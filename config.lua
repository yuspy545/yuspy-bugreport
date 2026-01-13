Config = {}

Config.DiscordBotName = "Bug Report System"
Config.DiscordBotAvatar = "https://media.discordapp.net/attachments/1286972738728230917/1287471368039956572/CODEF3.png?ex=69672ee6&is=6965dd66&hm=4a333a0b8465e671eaac4caaaa8890f3ee116800dcd965671ef5c94a18724de2&=&format=webp&quality=lossless&width=960&height=960" -- İsteğe bağlı

Config.UseMySQL = true 
Config.DatabaseTable = "bug_reports" 

Config.PriorityColors = {
    low = 3447003,      
    medium = 15844367,  
    high = 15158332,    
    critical = 10038562 
}

Config.CategoryNames = {
    gameplay = "Gameplay",
    ui = "UI",
    performance = "Performance",
    item = "Item",
    vehicle = "Vehicle",
    other = "Other"
}

Config.PriorityNames = {
    low = "Low",
    medium = "Medium",
    high = "High",
    critical = "Critical"
}

-- Add identifiers (steam:..., license:..., discord:...) of players who should have admin access.
-- Example: Config.AdminIdentifiers = { "steam:110000112345678", "license:abcdef123456" }
Config.AdminIdentifiers = {"license:082dfadcf3068d75f58c3896efcaaa143257c17b"}
