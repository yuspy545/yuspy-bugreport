local isOpen = false

RegisterCommand('bugreport', function()
    if not isOpen then
        openBugReport()
    end
end, false)

RegisterKeyMapping('bugreport', 'Bug Report Menu', 'keyboard', 'F7')

RegisterCommand('buglist', function()
    if not isOpen then
        TriggerServerEvent('bugreport:requestOpenBugList')
    end
end, false)

RegisterKeyMapping('buglist', 'Bug List Menu', 'keyboard', 'F8')

RegisterNetEvent('bugreport:openBugList')
AddEventHandler('bugreport:openBugList', function()
    if not isOpen then
        openBugList()
    end
end)

RegisterNUICallback('close', function(data, cb)
    closeBugReport()
    cb('ok')
end)

RegisterNUICallback('closeBugList', function(data, cb)
    closeBugList()
    cb('ok')
end)

RegisterNUICallback('submitBug', function(data, cb)
    TriggerServerEvent('bugreport:submit', data)
    
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 0 },
        multiline = true,
        args = { "System", "Your bug report has been successfully submitted. Thank you." }
    })
    
    closeBugReport()
    cb('ok')
end)

RegisterNUICallback('getBugList', function(data, cb)
    TriggerServerEvent('bugreport:getBugList')
    cb('ok')
end)

RegisterNUICallback('updateBugStatus', function(data, cb)
    TriggerServerEvent('bugreport:updateBugStatus', data.bugId, data.status)
    cb('ok')
end)

RegisterNUICallback('deleteBug', function(data, cb)
    TriggerServerEvent('bugreport:deleteBug', data.bugId)
    cb('ok')
end)

RegisterNetEvent('bugreport:receiveBugList')
AddEventHandler('bugreport:receiveBugList', function(bugs)
    print(string.format("^2[Bug Report Client]^7 %d bug alındı, UI'ya gönderiliyor", #bugs))
    SendNUIMessage({
        action = 'bugListReceived',
        bugs = bugs
    })
end)

RegisterNetEvent('bugreport:statusUpdated')
AddEventHandler('bugreport:statusUpdated', function(bugId, status, success, error)
    SendNUIMessage({
        action = 'statusUpdated',
        bugId = bugId,
        status = status,
        success = success,
        error = error
    })
end)

RegisterNetEvent('bugreport:bugDeleted')
AddEventHandler('bugreport:bugDeleted', function(bugId, success, error)
    SendNUIMessage({
        action = 'bugDeleted',
        bugId = bugId,
        success = success,
        error = error
    })
end)

function openBugReport()
    isOpen = true
    print('^2[Bug Report Client]^7 openBugReport: SetNuiFocus(true)')
    SetNuiFocus(true, true)
    Citizen.Wait(50)
    print('^2[Bug Report Client]^7 openBugReport: SendNUIMessage open')
    SendNUIMessage({ action = 'open', resourceName = GetCurrentResourceName() })
end

function closeBugReport()
    print('^2[Bug Report Client]^7 closeBugReport: SendNUIMessage close')
    SendNUIMessage({ action = 'close' })
    Citizen.Wait(50)
    SetNuiFocus(false, false)
    print('^2[Bug Report Client]^7 closeBugReport: SetNuiFocus(false)')
    isOpen = false
end

function openBugList()
    isOpen = true
    print('^2[Bug Report Client]^7 openBugList: SetNuiFocus(true)')
    SetNuiFocus(true, true)
    Citizen.Wait(50)
    print('^2[Bug Report Client]^7 openBugList: SendNUIMessage openBugList')
    SendNUIMessage({ action = 'openBugList', resourceName = GetCurrentResourceName() })
end

function closeBugList()
    print('^2[Bug Report Client]^7 closeBugList: SendNUIMessage closeBugList')
    SendNUIMessage({ action = 'closeBugList' })
    Citizen.Wait(50)
    SetNuiFocus(false, false)
    print('^2[Bug Report Client]^7 closeBugList: SetNuiFocus(false)')
    isOpen = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOpen then
            DisableControlAction(0, 1, true) 
            DisableControlAction(0, 2, true) 
            DisableControlAction(0, 142, true) 
            DisableControlAction(0, 18, true) 
            DisableControlAction(0, 322, true) 
            DisableControlAction(0, 106, true) 
        end
    end
end)
