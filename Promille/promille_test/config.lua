Config = {}

Config.TestItem = "promilletester"
Config.RequiredPermission = "police.breathalyzer"
Config.MaxDistance = 3.0

Config.PromilleDecayPerMinute = 0.02
Config.MinPromille = 0.0

Config.Messages = {
  NoPlayer = "Ingen spiller i naerheden.",
  NoPermission = "Du har ikke adgang til at bruge promilletesteren.",
  Result = "Promille for %s: %.2f",
}

Config.Notify = function(msg)
  TriggerEvent("chat:addMessage", {
    color = { 255, 200, 80 },
    args = { "Promille", msg },
  })
end
