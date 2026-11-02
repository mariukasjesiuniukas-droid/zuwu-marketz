// Public, read-only Discord member count for the configured ZUWU guild.
module.exports=async function handler(req,res){
  if(req.method!=='GET'){res.setHeader('Allow','GET');return res.status(405).json({error:'Method not allowed'})}
  const {DISCORD_BOT_TOKEN,DISCORD_GUILD_ID}=process.env;
  if(!DISCORD_BOT_TOKEN||!DISCORD_GUILD_ID)return res.status(503).json({error:'Discord stats not configured'});
  try{const r=await fetch(`https://discord.com/api/v10/guilds/${DISCORD_GUILD_ID}?with_counts=true`,{headers:{Authorization:`Bot ${DISCORD_BOT_TOKEN}`}});const d=await r.json().catch(()=>({}));if(!r.ok)return res.status(502).json({error:'Discord stats unavailable'});return res.status(200).json({memberCount:Number(d.approximate_member_count)||0,onlineCount:Number(d.approximate_presence_count)||0})}
  catch(e){console.error('Discord stats error:',e);return res.status(502).json({error:'Discord stats unavailable'})}
};
