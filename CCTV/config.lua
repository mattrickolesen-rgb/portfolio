Config = {}

Config.Command = 'cctv'

Config.JobName = 'kamera_opsaetter'

Config.ExitKey = 194 -- Backspace
Config.SwitchLeftKey = 174 -- Arrow Left
Config.SwitchRightKey = 175 -- Arrow Right
Config.RecordKey = 47 -- G
Config.RewatchKey = 168 -- F7
Config.PlaceKey = 38 -- E

Config.SnapshotIntervalMs = 2000
Config.MaxSnapshotsPerCam = 30
Config.PlaceDistance = 30.0
Config.DefaultFov = 60.0

Config.Cameras = {
  {
    label = 'Vinewood Blvd',
    coords = vector3(357.12, 277.83, 103.11),
    rot = vector3(-15.0, 0.0, 180.0),
    fov = 60.0
  },
  {
    label = 'Legion Sq',
    coords = vector3(169.56, -1004.57, 40.12),
    rot = vector3(-20.0, 0.0, 70.0),
    fov = 60.0
  },
  {
    label = 'Del Perro Pier',
    coords = vector3(-1603.85, -1046.68, 28.35),
    rot = vector3(-15.0, 0.0, 320.0),
    fov = 65.0
  }
}
