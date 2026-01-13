
local DiscordWebhook = "https://discord.com/api/webhooks/1287472632802840656/BlPZdvJORFwIe7Yx4xeSCTQUKn_fcft8aoT5AFqmftrjJFPlZcYzw-noy63p2FfWd3hQ" 


CreateThread(function()
    if Config.UseMySQL then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:execute([[
                CREATE TABLE IF NOT EXISTS `bug_reports` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `player_id` varchar(50) DEFAULT NULL,
                    `player_name` varchar(100) DEFAULT NULL,
                    `title` varchar(255) NOT NULL,
                    `category` varchar(50) NOT NULL,
                    `description` text NOT NULL,
                    `steps` text DEFAULT NULL,
                    `priority` varchar(20) DEFAULT 'medium',
                    `status` varchar(20) DEFAULT 'pending',
                    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]])
            print("^2[Bug Report]^7 Database table created (oxmysql)")
        else
            print("^1[Bug Report]^7 ERROR: oxmysql resource not found!")
        end
    else
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `bug_reports` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `player_id` varchar(50) DEFAULT NULL,
                `player_name` varchar(100) DEFAULT NULL,
                `title` varchar(255) NOT NULL,
                `category` varchar(50) NOT NULL,
                `description` text NOT NULL,
                `steps` text DEFAULT NULL,
                `priority` varchar(20) DEFAULT 'medium',
                `status` varchar(20) DEFAULT 'pending',
                `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        print("^2[Bug Report]^7 Database table created (MySQL)")
    end
end)

RegisterServerEvent('bugreport:submit')
AddEventHandler('bugreport:submit', function(bugData)
    local src = source
    local playerName = GetPlayerName(src)
    local playerId = GetPlayerIdentifier(src, 0)
    
    if Config.UseMySQL then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:insert('INSERT INTO bug_reports (player_id, player_name, title, category, description, steps, priority) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                playerId,
                playerName,
                bugData.title,
                bugData.category,
                bugData.description,
                bugData.steps or '',
                bugData.priority
            }, function(insertId)
                if insertId then
                    print(string.format("^2[Bug Report]^7 New bug report saved - ID: %d", insertId))
                    sendToDiscord(src, playerName, playerId, bugData, insertId)
                else
                    print("^1[Bug Report]^7 ERROR: Failed to save bug report!")
                end
            end)
        else
            print("^1[Bug Report]^7 HATA: oxmysql resource'u bulunamadı!")
        end
    else
        -- Eski MySQL
        MySQL.Async.insert('INSERT INTO bug_reports (player_id, player_name, title, category, description, steps, priority) VALUES (@playerId, @playerName, @title, @category, @description, @steps, @priority)', {
            ['@playerId'] = playerId,
            ['@playerName'] = playerName,
            ['@title'] = bugData.title,
            ['@category'] = bugData.category,
            ['@description'] = bugData.description,
            ['@steps'] = bugData.steps or '',
            ['@priority'] = bugData.priority
        }, function(insertId)
                if insertId then
                print(string.format("^2[Bug Report]^7 New bug report saved - ID: %d", insertId))
                sendToDiscord(src, playerName, playerId, bugData, insertId)
            else
                print("^1[Bug Report]^7 ERROR: Failed to save bug report!")
            end
        end)
    end
end)

function sendToDiscord(source, playerName, playerId, bugData, reportId)
    if not DiscordWebhook or DiscordWebhook == "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN" then
        print("^3[Bug Report]^7 WARNING: The Discord webhook URL is not set! (Set the DiscordWebhook variable in the server.lua file)")
        return
    end
    
    local categoryName = Config.CategoryNames[bugData.category] or bugData.category
    local priorityName = Config.PriorityNames[bugData.priority] or bugData.priority
    local priorityColor = Config.PriorityColors[bugData.priority] or Config.PriorityColors.medium
    
    local embed = {
        {
            ["title"] = "🐛 New Bug Report",
            ["description"] = string.sub(bugData.description, 1, 2000), 
            ["color"] = priorityColor,
            ["fields"] = {
                {
                    ["name"] = "📋 Title",
                    ["value"] = bugData.title,
                    ["inline"] = false
                },
                {
                    ["name"] = "👤 Player",
                    ["value"] = playerName .. " (" .. playerId .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "🏷️ Category",
                    ["value"] = categoryName,
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Priority",
                    ["value"] = priorityName,
                    ["inline"] = true
                },
                {
                    ["name"] = "🆔 Report ID",
                    ["value"] = "#" .. reportId,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = os.date("%d/%m/%Y %H:%M:%S")
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    if bugData.steps and bugData.steps ~= "" then
        table.insert(embed[1].fields, {
            ["name"] = "📝 How is it done?",
            ["value"] = string.sub(bugData.steps, 1, 1000),
            ["inline"] = false
        })
    end
    
    local data = {
        username = Config.DiscordBotName,
        avatar_url = Config.DiscordBotAvatar,
        embeds = embed
    }
    
    PerformHttpRequest(DiscordWebhook, function(err, text, headers)
        if err == 200 or err == 204 then
            print("^2[Bug Report]^7 Successfully sent to Discord.!")
        else
            print("^1[Bug Report]^7 An error occurred while sending to Discord.: " .. tostring(err))
        end
    end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

RegisterServerEvent('bugreport:getBugList')
AddEventHandler('bugreport:getBugList', function()
    local src = source
    
    print(string.format("^2[Bug Report]^7 Bug listesi isteniyor - Player: %d", src))
    
    if Config.UseMySQL then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:query('SELECT * FROM bug_reports ORDER BY created_at DESC', {}, function(results)
                if results then
                    print(string.format("^2[Bug Report]^7 %d bugs found, sending to client", #results))
                    TriggerClientEvent('bugreport:receiveBugList', src, results)
                else
                    print("^3[Bug Report]^7 No results or empty")
                    TriggerClientEvent('bugreport:receiveBugList', src, {})
                end
            end)
        else
            print("^1[Bug Report]^7 HATA: oxmysql resource'u bulunamadı!")
            TriggerClientEvent('bugreport:receiveBugList', src, {})
        end
    else
        MySQL.Async.fetchAll('SELECT * FROM bug_reports ORDER BY created_at DESC', {}, function(results)
            if results then
                print(string.format("^2[Bug Report]^7 %d bugs found, sending to client", #results))
                TriggerClientEvent('bugreport:receiveBugList', src, results)
            else
                print("^3[Bug Report]^7 No results or empty")
                TriggerClientEvent('bugreport:receiveBugList', src, {})
            end
        end)
    end
end)


local function isAdmin(playerSrc)
    if playerSrc == 0 then return true end
    local identifiers = GetPlayerIdentifiers(playerSrc) or {}
    for _, id in ipairs(identifiers) do
        for _, adminId in ipairs(Config.AdminIdentifiers or {}) do
            if id == adminId then
                return true
            end
        end
    end
    if IsPlayerAceAllowed then
        local ok, res = pcall(IsPlayerAceAllowed, playerSrc, "yuspy-bugreport.admin")
        if ok and res then return true end
    end
    return false
end

RegisterServerEvent('bugreport:updateBugStatus')
AddEventHandler('bugreport:updateBugStatus', function(bugId, status)
    local src = source
    
    if status ~= 'pending' and status ~= 'checked' and status ~= 'fixed' then
        TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, false, "Invalid status")
        return
    end
    
    if Config.UseMySQL then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:update('UPDATE bug_reports SET status = ? WHERE id = ?', {status, bugId}, function(affectedRows)
                if affectedRows > 0 then
                    print(string.format("^2[Bug Report]^7 Bug #%d status updated to '%s'", bugId, status))
                    TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, true, nil)
                else
                    TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, false, "Bug not found")
                end
            end)
        else
            TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, false, "oxmysql not found")
        end
    else
        MySQL.Async.execute('UPDATE bug_reports SET status = @status WHERE id = @id', {
            ['@status'] = status,
            ['@id'] = bugId
        }, function(affectedRows)
            if affectedRows > 0 then
                print(string.format("^2[Bug Report]^7 Bug #%d durumu '%s' olarak güncellendi", bugId, status))
                TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, true, nil)
            else
                TriggerClientEvent('bugreport:statusUpdated', src, bugId, status, false, "Bug not found")
            end
        end)
    end
end)

RegisterServerEvent('bugreport:deleteBug')
AddEventHandler('bugreport:deleteBug', function(bugId)
    local src = source
    
    if Config.UseMySQL then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:query('SELECT status FROM bug_reports WHERE id = ?', {bugId}, function(results)
                if results and #results > 0 then
                    if results[1].status == 'fixed' then
                        exports.oxmysql:execute('DELETE FROM bug_reports WHERE id = ?', {bugId}, function(affectedRows)
                            local rows = 0
                            if type(affectedRows) == 'number' then
                                rows = affectedRows
                            elseif type(affectedRows) == 'table' then
                                if affectedRows.affectedRows and type(affectedRows.affectedRows) == 'number' then
                                    rows = affectedRows.affectedRows
                                elseif #affectedRows > 0 and type(affectedRows[1]) == 'table' and affectedRows[1].affectedRows then
                                    rows = affectedRows[1].affectedRows
                                end
                            end

                            if rows > 0 then
                                print(string.format("^2[Bug Report]^7 Bug #%d deleted", bugId))
                                TriggerClientEvent('bugreport:bugDeleted', src, bugId, true, nil)
                            else
                                TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Failed to delete")
                            end
                        end)
                    else
                        TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Only fixed bugs can be deleted")
                    end
                else
                    TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Bug not found")
                end
            end)
        else
            TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "oxmysql not found")
        end
    else
        MySQL.Async.fetchAll('SELECT status FROM bug_reports WHERE id = @id', {
            ['@id'] = bugId
        }, function(results)
            if results and #results > 0 then
                if results[1].status == 'fixed' then
                    MySQL.Async.execute('DELETE FROM bug_reports WHERE id = @id', {
                        ['@id'] = bugId
                    }, function(affectedRows)
                        if type(affectedRows) == 'number' and affectedRows > 0 then
                            print(string.format("^2[Bug Report]^7 Bug #%d deleted", bugId))
                            TriggerClientEvent('bugreport:bugDeleted', src, bugId, true, nil)
                        else
                            TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Failed to delete")
                        end
                    end)
                else
                    TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Only fixed bugs can be deleted")
                end
            else
                TriggerClientEvent('bugreport:bugDeleted', src, bugId, false, "Bug not found")
            end
        end)
    end
end)

RegisterCommand('buglist', function(source, args, rawCommand)
    local src = source

    if not isAdmin(src) then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1[Bug Report]', 'You do not have permission to use this command.' } })
        return
    end

    TriggerClientEvent('bugreport:openBugList', src)
end, false)

RegisterNetEvent('bugreport:requestOpenBugList')
AddEventHandler('bugreport:requestOpenBugList', function()
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('chat:addMessage', src, { args = { '^1[Bug Report]', 'You do not have permission to use this command.' } })
        return
    end
    TriggerClientEvent('bugreport:openBugList', src)
end)
