// Vercel serverless function: creates a private Discord ticket for an existing ZUWU order.
// Required Vercel environment variables are documented in README-DISCORD-TICKETS.txt.

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DISCORD_BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;
const DISCORD_GUILD_ID = process.env.DISCORD_GUILD_ID;
const DISCORD_TICKET_CATEGORY_ID = process.env.DISCORD_TICKET_CATEGORY_ID;
const DISCORD_STAFF_ROLE_ID = process.env.DISCORD_STAFF_ROLE_ID;

function reply(res, status, body) {
  return res.status(status).json(body);
}

async function discordRequest(path, options = {}) {
  const response = await fetch(`https://discord.com/api/v10${path}`, {
    ...options,
    headers: {
      Authorization: `Bot ${DISCORD_BOT_TOKEN}`,
      'Content-Type': 'application/json',
      ...(options.headers || {})
    }
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = data.message || `Discord API error (${response.status})`;
    const error = new Error(detail);
    error.status = response.status;
    throw error;
  }
  return data;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return reply(res, 405, { error: 'Naudok POST metodą.' });
  }

  const missing = [
    ['SUPABASE_URL', SUPABASE_URL],
    ['SUPABASE_ANON_KEY', SUPABASE_ANON_KEY],
    ['SUPABASE_SERVICE_ROLE_KEY', SUPABASE_SERVICE_ROLE_KEY],
    ['DISCORD_BOT_TOKEN', DISCORD_BOT_TOKEN],
    ['DISCORD_GUILD_ID', DISCORD_GUILD_ID],
    ['DISCORD_TICKET_CATEGORY_ID', DISCORD_TICKET_CATEGORY_ID]
  ].filter(([, value]) => !value).map(([name]) => name);
  if (missing.length) {
    return reply(res, 500, { error: `Vercel trūksta Environment Variable: ${missing.join(', ')}` });
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
  if (!accessToken) return reply(res, 401, { error: 'Prisijunk iš naujo.' });

  const { orderId } = req.body || {};
  if (typeof orderId !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(orderId)) {
    return reply(res, 400, { error: 'Neteisingas užsakymo ID.' });
  }

  const supabaseHeaders = {
    apikey: SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    'Content-Type': 'application/json'
  };

  try {
    // Verify the caller's access token with Supabase Auth; never trust a user ID from the browser.
    const authResponse = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${accessToken}` }
    });
    const authUser = await authResponse.json().catch(() => ({}));
    if (!authResponse.ok || !authUser.id) return reply(res, 401, { error: 'Prisijungimo sesija nebegalioja. Prisijunk iš naujo.' });

    // Require a linked Discord OAuth identity, so the ticket can be granted to the correct Discord account.
    const identities = Array.isArray(authUser.identities) ? authUser.identities : [];
    const discordIdentity = identities.find(identity => identity.provider === 'discord');
    const discordUserId = discordIdentity && (
      discordIdentity.identity_data?.provider_id ||
      discordIdentity.identity_data?.sub ||
      discordIdentity.provider_id
    );
    if (!discordUserId || !/^\d{17,20}$/.test(String(discordUserId))) {
      return reply(res, 400, { error: 'Pirmiausia prisijunk prie ZUWU MARKET per Discord, kad galėtume suteikti prieigą prie ticketo.' });
    }

    const orderResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/orders?select=id,buyer_id,listing_id,amount,buyer_note,status&id=eq.${encodeURIComponent(orderId)}&limit=1`,
      { headers: supabaseHeaders }
    );
    const orders = await orderResponse.json().catch(() => []);
    if (!orderResponse.ok) return reply(res, 502, { error: 'Nepavyko patikrinti užsakymo Supabase.' });
    const order = Array.isArray(orders) ? orders[0] : null;
    if (!order) return reply(res, 404, { error: 'Užsakymas nerastas.' });
    if (order.buyer_id !== authUser.id) return reply(res, 403, { error: 'Šis užsakymas nepriklauso tavo paskyrai.' });

    const listingResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/listings?select=title&id=eq.${encodeURIComponent(order.listing_id)}&limit=1`,
      { headers: supabaseHeaders }
    );
    const listings = await listingResponse.json().catch(() => []);
    if (!listingResponse.ok) return reply(res, 502, { error: 'Nepavyko gauti prekės informacijos.' });
    const listing = Array.isArray(listings) ? listings[0] : null;
    const safeTitle = String(listing?.title || 'ZUWU užsakymas').replace(/[\r\n]/g, ' ').slice(0, 70);

    // Avoid creating duplicate channels if the buyer retries after a slow response.
    const existingChannels = await discordRequest(`/guilds/${DISCORD_GUILD_ID}/channels`);
    const existing = existingChannels.find(channel => channel.type === 0 && channel.topic === `zuwu-order:${order.id}`);
    if (existing) {
      return reply(res, 200, { ok: true, channelName: existing.name, url: `https://discord.com/channels/${DISCORD_GUILD_ID}/${existing.id}`, alreadyExists: true });
    }

    const me = await discordRequest('/users/@me');
    const guildEveryoneRoleId = DISCORD_GUILD_ID;
    const permissionOverwrites = [
      { id: guildEveryoneRoleId, type: 0, deny: '1024' }, // VIEW_CHANNEL
      { id: String(discordUserId), type: 1, allow: '68608' }, // VIEW_CHANNEL, SEND_MESSAGES, READ_MESSAGE_HISTORY
      { id: String(me.id), type: 1, allow: '68608' }
    ];
    if (DISCORD_STAFF_ROLE_ID) {
      permissionOverwrites.push({ id: DISCORD_STAFF_ROLE_ID, type: 0, allow: '68608' });
    }

    const channelName = `pirkti-${String(order.id).slice(0, 8)}`;
    const channel = await discordRequest(`/guilds/${DISCORD_GUILD_ID}/channels`, {
      method: 'POST',
      body: JSON.stringify({
        name: channelName,
        type: 0,
        parent_id: DISCORD_TICKET_CATEGORY_ID,
        topic: `zuwu-order:${order.id}`,
        permission_overwrites: permissionOverwrites
      })
    });

    const note = String(order.buyer_note || '').slice(0, 500);
    const content = [
      `**Naujas ZUWU MARKET užsakymas**`,
      `**Prekė:** ${safeTitle}`,
      `**Kaina:** ${Number(order.amount).toFixed(2)} €`,
      `**Užsakymo ID:** \`${order.id}\``,
      `**Pirkėjas:** <@${discordUserId}>`,
      `**Būsena:** ${String(order.status || 'pending_review')}`,
      note ? `**Pirkėjo pastaba:** ${note.replace(/@/g, '@\u200b')}` : '',
      '',
      'ZUWU komanda čia susisieks dėl šio užsakymo.'
    ].filter(Boolean).join('\n');

    try {
      await discordRequest(`/channels/${channel.id}/messages`, {
        method: 'POST',
        body: JSON.stringify({ content: content.slice(0, 1900), allowed_mentions: { parse: [], users: [String(discordUserId)] } })
      });
    } catch (messageError) {
      // Remove an empty channel if posting the ticket details fails.
      await discordRequest(`/channels/${channel.id}`, { method: 'DELETE' }).catch(() => {});
      throw messageError;
    }

    return reply(res, 200, { ok: true, channelName: channel.name, url: `https://discord.com/channels/${DISCORD_GUILD_ID}/${channel.id}` });
  } catch (error) {
    console.error('ZUWU Discord ticket error:', error);
    const status = error.status === 403 ? 502 : 502;
    return reply(res, status, { error: `Discord ticket nepavyko sukurti: ${error.message}` });
  }
};
