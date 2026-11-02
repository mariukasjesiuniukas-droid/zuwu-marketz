// Vercel function: creates one private Discord ticket for one or more ZUWU order rows.
const { SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, DISCORD_BOT_TOKEN, DISCORD_GUILD_ID, DISCORD_TICKET_CATEGORY_ID, DISCORD_STAFF_ROLE_ID } = process.env;
function reply(res,status,body){return res.status(status).json(body)}
async function discordRequest(path,options={}){
  const r=await fetch(`https://discord.com/api/v10${path}`,{...options,headers:{Authorization:`Bot ${DISCORD_BOT_TOKEN}`,'Content-Type':'application/json',...(options.headers||{})}});
  const d=await r.json().catch(()=>({})); if(!r.ok){const e=new Error(d.message||`Discord API error (${r.status})`);e.status=r.status;e.discordCode=d.code;throw e;} return d;
}
module.exports=async function handler(req,res){
  if(req.method!=='POST'){res.setHeader('Allow','POST');return reply(res,405,{error:'Naudok POST metodą.'})}
  const missing=[['SUPABASE_URL',SUPABASE_URL],['SUPABASE_ANON_KEY',SUPABASE_ANON_KEY],['SUPABASE_SERVICE_ROLE_KEY',SUPABASE_SERVICE_ROLE_KEY],['DISCORD_BOT_TOKEN',DISCORD_BOT_TOKEN],['DISCORD_GUILD_ID',DISCORD_GUILD_ID],['DISCORD_TICKET_CATEGORY_ID',DISCORD_TICKET_CATEGORY_ID]].filter(x=>!x[1]).map(x=>x[0]);
  if(missing.length)return reply(res,500,{error:`Vercel trūksta Environment Variable: ${missing.join(', ')}`});
  const auth=(req.headers.authorization||'').replace(/^Bearer\s+/i,'');if(!auth)return reply(res,401,{error:'Prisijunk iš naujo.'});
  const body=req.body||{};const orderIds=Array.isArray(body.orderIds)?body.orderIds:(typeof body.orderId==='string'?[body.orderId]:[]);
  if(!orderIds.length||orderIds.length>25||orderIds.some(id=>typeof id!=='string'||!/^[0-9a-f-]{36}$/i.test(id)))return reply(res,400,{error:'Neteisingi užsakymo ID.'});
  const sh={apikey:SUPABASE_SERVICE_ROLE_KEY,Authorization:`Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,'Content-Type':'application/json'};
  try{
    const au=await fetch(`${SUPABASE_URL}/auth/v1/user`,{headers:{apikey:SUPABASE_ANON_KEY,Authorization:`Bearer ${auth}`}});const u=await au.json().catch(()=>({}));
    if(!au.ok||!u.id)return reply(res,401,{error:'Prisijungimo sesija nebegalioja.'});
    const ident=(u.identities||[]).find(x=>x.provider==='discord');const discordId=ident&&(ident.identity_data?.provider_id||ident.identity_data?.sub||ident.provider_id);
    if(!discordId||!/^[0-9]{17,20}$/.test(String(discordId)))return reply(res,400,{error:'Pirmiausia prisijunk prie ZUWU MARKET per Discord.'});
    const filter=orderIds.map(encodeURIComponent).join(',');
    const or=await fetch(`${SUPABASE_URL}/rest/v1/orders?select=id,buyer_id,listing_id,amount,buyer_note,status,quantity,unit_price&id=in.(${filter})`,{headers:sh});const orders=await or.json().catch(()=>[]);
    if(!or.ok)return reply(res,502,{error:'Nepavyko patikrinti užsakymų Supabase.'});
    if(!Array.isArray(orders)||orders.length!==orderIds.length||orders.some(o=>o.buyer_id!==u.id))return reply(res,403,{error:'Vienas ar daugiau užsakymų nepriklauso tavo paskyrai.'});
    const listingIds=[...new Set(orders.map(o=>o.listing_id))];const lr=await fetch(`${SUPABASE_URL}/rest/v1/listings?select=id,title&id=in.(${listingIds.map(encodeURIComponent).join(',')})`,{headers:sh});const listings=await lr.json().catch(()=>[]);if(!lr.ok)return reply(res,502,{error:'Nepavyko gauti prekių informacijos.'});
    const titles=Object.fromEntries((listings||[]).map(x=>[x.id,x.title]));
    const key=orderIds.slice().sort().join(',');const topic=`zuwu-cart:${key}`;
    const channels=await discordRequest(`/guilds/${DISCORD_GUILD_ID}/channels`);const existing=channels.find(c=>c.type===0&&c.topic===topic);
    if(existing)return reply(res,200,{ok:true,channelName:existing.name,url:`https://discord.com/channels/${DISCORD_GUILD_ID}/${existing.id}`,alreadyExists:true});
    const me=await discordRequest('/users/@me');const overwrites=[{id:DISCORD_GUILD_ID,type:0,deny:'1024'},{id:String(discordId),type:1,allow:'68608'},{id:String(me.id),type:1,allow:'68608'}];if(DISCORD_STAFF_ROLE_ID)overwrites.push({id:DISCORD_STAFF_ROLE_ID,type:0,allow:'68608'});
    const channel=await discordRequest(`/guilds/${DISCORD_GUILD_ID}/channels`,{method:'POST',body:JSON.stringify({name:`zuwu-${String(orders[0].id).slice(0,8)}`,type:0,parent_id:DISCORD_TICKET_CATEGORY_ID,topic,permission_overwrites:overwrites})});
    const lines=orders.map((o,i)=>`${i+1}. **${String(titles[o.listing_id]||'Prekė').replace(/[\r\n]/g,' ').slice(0,70)}** × ${Number(o.quantity||1)} — **${Number(o.amount).toFixed(2)} €**`).join('\n');
    const total=orders.reduce((sum,o)=>sum+Number(o.amount),0);const note=String(orders[0].buyer_note||'').slice(0,500).replace(/@/g,'@\u200b');
    const content=[`**Naujas ZUWU MARKET krepšelio užsakymas**`,`**Pirkėjas:** <@${discordId}>`,``,`**Prekės:**`,lines,``,`**Galutinė suma:** **${total.toFixed(2)} €**`,`**Užsakymo ID:** ${orders.map(o=>`\`${o.id}\``).join(', ')}`,`**Būsena:** Laukiama peržiūros`,note?`**Pastaba:** ${note}`:'','ZUWU komanda čia susisieks dėl užsakymo.'].filter(Boolean).join('\n');
    try{await discordRequest(`/channels/${channel.id}/messages`,{method:'POST',body:JSON.stringify({content:content.slice(0,1900),allowed_mentions:{parse:[],users:[String(discordId)]}})})}catch(e){await discordRequest(`/channels/${channel.id}`,{method:'DELETE'}).catch(()=>{});throw e}
    return reply(res,200,{ok:true,channelName:channel.name,url:`https://discord.com/channels/${DISCORD_GUILD_ID}/${channel.id}`});
  }catch(e){console.error('ZUWU Discord ticket error:',e);return reply(res,502,{error:`Discord ticket nepavyko sukurti: ${e.message}${e.discordCode?` (Discord code ${e.discordCode})`:''}`})}
};
