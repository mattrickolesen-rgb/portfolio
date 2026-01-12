Config = {}

Config.permission = 'dommer.adgang'
Config.maxResults = 25
Config.searchMinLength = 2

-- vrp_user_identities is default in vRP1
Config.identityTable = 'vrp_user_identities'
Config.identityIdColumn = 'user_id'
Config.identityFirstnameColumn = 'firstname'
Config.identityLastnameColumn = 'name'
Config.identityPhoneColumn = 'phone'
Config.identityRegColumn = 'registration'

Config.phone = {
  enabled = false,
  mode = 'event', -- 'event' or 'export'
  resource = 'ib-phone',
  event = 'ib-phone:sendMessage',
  export = 'SendMessage',
  sender = 'Domstolen',
  useClientEvent = false
}
