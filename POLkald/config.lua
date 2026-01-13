Config = {}

Config.RigspolitichefenUserId = 2526

-- vRP group names used for roles
Config.RoleGroups = {
  Politi = 'politi',
  Leder = 'leder',
  Oeversteledelse = 'oversteledelse'
}

-- vRP group names used for departments
Config.DepartmentGroups = {
  Politiskolen = 'politiskolen',
  BerdskGroen = 'berdsk_groen',
  BerdskGul = 'berdsk_gul',
  RKS = 'rks',
  OperativFaerdsel = 'operativ_faerdsel',
  SagsAdmin = 'sags_admin',
  NaerPolitiet = 'naerpolitiet',
  Vagtcentralen = 'vagtcentralen'
}

-- Duty statuses and required permissions
Config.CallTimeoutSeconds = 20
Config.EmergencyNumber = '112'

-- lb-phone integration hook: set to true if you want to open the app through lb-phone
Config.UseLBPhoneExport = true
Config.LBPhoneResource = 'lb-phone'
Config.LBPhoneAppId = 'polkald'
Config.LBPhoneAppLabel = 'POLkald'
Config.LBPhoneAppIcon = 'https://cdn-icons-png.flaticon.com/512/2991/2991108.png'
