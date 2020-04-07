data = {
  level = 3,
  perception = 4,

  to_hit = 7,
  attack_die_count = 1,
  attack_die_size = 6,
  attack_die_modifier = 4,

  fort_save = 9,
  will_save = 9,
  reflex_save = 6
}

character_name = 'Benedict Flameblade'
character_attack_line = 'strikes with flaming fury!'

data_obj = nil

self_obj = nil

function onLoad(save_state)
  -- Add commands to the table here
  my_commands = {
    attack = attack,
    perception = perception,

    fort = fort_save,
    reflex = reflex_save,
    will = will_save,

    test = test,
    template = template
  }

  -- keybinds
  keybinds = {
    fort_save, -- 1
    reflex_save, -- 2
    will_save, -- 3
    perception, -- 4
    attack -- 5
  }

  self_obj = self
end

function onExternalCommand(input)
  print('VSCode: ' .. input)
end

function onScriptingButtonDown(index, color)
  local player = Player[color]
  local fn = keybinds[index]
  if fn ~= nil then
    fn(player)
  end
end

-- Allow a object with a name matching our charater to be dropped onto the character as a data source
-- The description is parsed as key: value and injected into the data map
function onCollisionEnter(info)
  local inc_obj = info.collision_object
  local is_data = inc_obj.getName() == character_name

  if is_data then
    data_obj = inc_obj
  end
end

function parse_command(message)
  if string.find(message, '#', 1) == 1 then
    local all_args = {}
    for word in string.gmatch(string.sub(message, 2), '%S+') do
      table.insert(all_args, word)
    end
    local command = table.remove(all_args, 1)
    return command, all_args
  end

  return nil, nil
end

function execute_command(message)
  local command, args = parse_command(message)
  if my_commands[command] ~= nil then
    my_commands[command](player, args)
  else
    printToAll('Command not found')
  end
end

function onChat(message, player)
  if(player.steam_name == self.getDescription()) then
    execute_command(message)
  end
end

function template(player, args)
  local type = args[1]
  SpellTemplates.SpawnTemplate(self_obj, type)
end

function perception(player)
  -- To hit
  local to_hit_sum, to_hit_values = xdx(1, 20)

  -- Modifier
  local to_hit_mod = get_data_value('level') + get_data_value('perception')

  local to_hit_total = to_hit_sum + to_hit_mod
  printToAll(
      'Perception: '..
      to_hit_total ..
      ' <' .. printList(to_hit_values) .. '>' ..
      ' + ' ..
      to_hit_mod
  )
end

function attack(player)
  -- To hit
  local to_hit_sum, to_hit_values = xdx(1, 20)

  -- Modifier
  local to_hit_mod = get_data_value('to_hit')

  local to_hit_total = to_hit_sum + to_hit_mod

  printToAll(
      'To hit: '..
      to_hit_total ..
      ' (<' .. printList(to_hit_values) .. '>' ..
      ' + ' ..
      to_hit_mod .. ')'
  )

  -- Damage

  -- Dice

  local dmg_sum, dmg_values = xdx(get_data_value('attack_die_count'), get_data_value('attack_die_size'))

  -- Modifier
  local dmg_mod = get_data_value('attack_die_modifier')

  local dmg_total = dmg_sum + dmg_mod
  printToAll(
      'Damage: '..
      dmg_total ..
      ' (<' .. printList(dmg_values) .. '>' ..
      ' + ' ..
      dmg_mod .. ')'
  )

  -- Broadcast
  broadcastToAll(
    character_name..' '..
    character_attack_line..'  '..
    'To hit: '..to_hit_total..
    '  Damage: '..dmg_total, { r=0.6, g=0, b=0 }
  )
end

function fort_save(player)
  return save(player, 'fort')
end

function will_save(player)
  return save(player, 'will')
end

function reflex_save(player)
  return save(player, 'reflex')
end

function save(player, type)
  local mod = get_data_value(type..'_save')
  local roll, roll_values = xdx(1, 20)

  broadcastToAll(
    character_name..' makes a '..type..' save: '..(roll + mod)..
    ' (<' .. printList(roll_values) .. '> + '..mod..')',
    { r=0.6, g=0, b=0 }
  )
end

-- Helper functions

function parse_data_obj_description()
  if data_obj == nil then
    return nil
  end

  -- Parse to data table
  local parsed_data = {}
  local lines = data_obj.getDescription():gmatch("[^\r\n]+")
  for line in lines do
    local split_line = line:gmatch(":%S+")
    for k, v in line:gmatch("(%S+):%s+(%S+)") do
      key = snake(k)
      value = tonumber(v) or v
    end

    parsed_data[key] = value
  end

  -- Add in any special cases

  -- Parse an "attack" field like "2d6+4" into component parts
  if parsed_data['attack'] then
    local value, size, mod = parsed_data['attack']:match("(%d+)d(%d+)+(%d+)")
    parsed_data['attack_die_count'] = tonumber(value)
    parsed_data['attack_die_size'] = tonumber(size)
    parsed_data['attack_die_modifier'] = tonumber(mod)
  end

  return parsed_data
end

function snake(s)
  s = s:gsub("%s+", "")
  return s:gsub('%f[^%l]%u','_%1'):gsub('%f[^%a]%d','_%1'):gsub('%f[^%d]%a','_%1'):gsub('(%u)(%u%l)','%1_%2'):lower()
end

-- Fetches a value from our bound data object, or from static data in this script
function get_data_value(name)
  local parsed_data = parse_data_obj_description()
  local val = nil

  if parsed_data ~= nil then
    val = parsed_data[name] or data[name]
  else
    val = data[name]
  end

  if type(val) == 'function' then
    return val()
  else
    return val
  end
end

function xdx(n, max_val)
    local sum = 0
    local values = {}
    for i=1,n do
        result = math.random(1, max_val)
        sum = sum + result
        table.insert(values, result)
    end
    return sum, values
end

function printList(values)
    local comps = ''
    for index, data in ipairs(values) do
        if index ~= #values then
            comps = comps .. data .. ', '
        else
            comps = comps .. data
        end
    end
    return comps
end

-- CLI

-- Attempts to determine if we're in TTS or not
function isTTS()
  return os == nil or os.getenv == nil
end

-- Tests

function test()
  test_snake()
  test_data_load()
  test_parse_command()
end

function test_data_load()
  local data = {
    getName = function() return 'Benedict Flameblade' end,
    getDescription = function()
      return [[
        Level: 4
  
        To Hit: 7
        Attack: 2d6+4
      ]]
    end
  }

  data_obj = data

  assert(get_data_value('level') == 4, 'Failed to get level value, got: '..get_data_value('level'))
  assert(get_data_value('perception') == 4, 'Failed to get perception value, got: '..get_data_value('perception'))
  assert(get_data_value('attack_die_count') == 2, 'Failed to get attack_die_count value, got: '..get_data_value('attack_die_count'))
  assert(get_data_value('attack_die_size') == 6, 'Failed to get attack_die_size value, got: '..get_data_value('attack_die_size'))
  assert(get_data_value('attack_die_modifier') == 4, 'Failed to get attack_die_modifier value, got: '..get_data_value('attack_die_modifier'))
end

function test_snake() 
  assert(snake('FooBar') == 'foo_bar', 'Failed to snake case PascalCase')
  assert(snake('fooBar') == 'foo_bar', 'Failed to snake case camelCase')
end

function test_parse_command() 
  assert(parse_command('#attack') == 'attack', 'Failed to parse command #attack')
end

-- Main

if not isTTS() then
  if os.getenv("TEST") ~= nil then
    test()
  else
    -- CLI

    -- Need to stub some TTS library functions
    function printToAll(message, color)
      print(message)
    end

    function broadcastToAll(message, color)
      print(message)
    end

    Player = {
      color = 'commandline'
    }

    -- Use the same entry point for command globals
    onLoad()

    command = '#'..arg[1]
    execute_command(command)
  end
end

-- Code based on  the most excellent XWing Unified 2.0 mod

SpellTemplates = {}

-- Table of existing spawned templates
-- Entry: {obj=objectRef, template=templateRef, type=templateCode}
SpellTemplates.spawnedTemplates = {}

-- Click function for template button (destroy)
function SpellTemplate_SelfDestruct(obj)
  for k, rTable in pairs(SpellTemplates.spawnedTemplates) do
    if rTable.template == obj then
      table.remove(SpellTemplates.spawnedTemplates, k)
      break
    end
  end
  obj.destruct()
end

-- Remove appropriate entry if template is destroyed
SpellTemplates.onObjectDestroyed = function(obj)
  for k,info in pairs(SpellTemplates.spawnedTemplates) do
    if info.obj == obj or info.template == obj then
      if info.obj == obj then info.template.destruct() end
      table.remove(SpellTemplates.spawnedTemplates, k)
      break
    end
  end
end

-- TEMPLATE MESHES DATABASE
SpellTemplates.meshes = {}
SpellTemplates.scales = {}
SpellTemplates.scale = {0.09, 0.09, 0.09}
SpellTemplates.meshes.radius_5ft = 'file:///Users/jcavanagh/tts_templates/Spell_Markers_5_ft_radius.stl.obj'
SpellTemplates.scales.radius_5ft = {0.09, 0.09, 0.09}
SpellTemplates.meshes.radius_10ft = 'file:///Users/jcavanagh/tts_templates/Spell_Markers_10_ft_radius.stl.obj'
SpellTemplates.scales.radius_10ft = {0.08, 0.08, 0.08}
SpellTemplates.meshes.radius_15ft = 'file:///Users/jcavanagh/tts_templates/Spell_Markers_15_ft_radius.stl.obj'
SpellTemplates.scales.radius_15ft = {0.075, 0.075, 0.075}
SpellTemplates.meshes.radius_20ft = 'file:///Users/jcavanagh/tts_templates/Spell_Markers_20_ft_radius.stl.obj'
SpellTemplates.scales.radius_20ft = {0.07, 0.07, 0.07}

-- Avaialble template codes:
-- R5            - 5ft radius
-- R10           - 10ft radius
-- R15           - 15ft radius
-- R20           - 20ft radius
-- Translate template code to a mesh entry
SpellTemplates.typeToKey = {}
SpellTemplates.typeToKey['R'] = 'radius'

-- Get template spawn tables for some object and some template code
-- Return table with "mesh", "collider" and "scale" keys
--  (for appropriate template)
SpellTemplates.GetTemplateData = function(obj, templateType)
  local out = {mesh = nil, collider = nil, scale = nil}
  printToAll(templateType)
  if templateType:sub(1,1) == 'R' then
    rKey = tonumber(templateType:sub(2))
    printToAll(rKey)
    out.mesh = SpellTemplates.meshes['radius_'..rKey..'ft']
    out.scale = SpellTemplates.scales['radius_'..rKey..'ft']
  end
  -- out.scale = SpellTemplates.scale
  out.collider = nil
  return out
end

-- Return a descriptive arc name of command (for announcements)
SpellTemplates.DescriptiveName = function(obj, templateType)
  if templateType:sub(1,1) == 'R' then
    ranges = templateType:sub(2,2)
    return ranges .. 'ft radius'
  end
end

-- Create tables for spawning a template
-- Return:  {
--      params      <- table suitable for spawnObject(params) call
--      custom      <- table suitable for obj.setCustomObject(custom) call
--          }
SpellTemplates.CreateCustomTables = function(obj, templateType)
  local templateData = SpellTemplates.GetTemplateData(obj, templateType)
  local paramsTable = {}
  paramsTable.type = 'Custom_Model'
  paramsTable.position = obj.getPosition()
  paramsTable.rotation = {90, obj.getRotation()[2], 0}
  -- if templateType == 'B' then
  --   if ModelDB.GetData(obj).baseSize == 'small' then
  --     rot = obj.getRotation()[2]
  --     paramsTable.rotation={0, rot +180, 0}
  --   end
  -- end
  -- if templateType == 'SR' then
  --   rot = obj.getRotation()[2]
  --   paramsTable.rotation= {0, rot + 180, 0}
  --   if ModelDB.GetData(obj).baseSize == 'medium' then                        --Side arc model for medium bases is inverted in relation to small and large bases, so it must be rotated 180 degrees as a workaround
  --     paramsTable.rotation= {0, rot, 0}
  --   end
  -- end
  -- if templateType == 'SL' and ModelDB.GetData(obj).baseSize == 'medium' then      --Side arc model for medium bases is inverted in relation to small and large bases, so it must be rotated 180 degrees as a workaround
  --   rot = obj.getRotation()[2]
  --   paramsTable.rotation= {0, rot + 180 , 0}
  -- end
  
  paramsTable.scale = templateData.scale

  local customTable = {}
  customTable.mesh = templateData.mesh
  customTable.collider = templateData.collider

  return {params = paramsTable, custom = customTable}
end

-- Spawn a template for an object
-- Returns new template reference
SpellTemplates.SpawnTemplate = function(obj, templateType)
  local templateData = SpellTemplates.CreateCustomTables(obj, templateType)
  local newTemplate = spawnObject(templateData.params)
  newTemplate.setCustomObject(templateData.custom)
  table.insert(SpellTemplates.spawnedTemplates, {obj = obj, template = newTemplate, type = templateType})
  newTemplate.lock()
  newTemplate.setScale(templateData.params.scale)

  local button = {click_function = 'SpellTemplate_SelfDestruct', label = 'DEL', position = {0, 0.5, 0}, rotation =  {0, 0, 0}, width = 900, height = 900, font_size = 250}
  newTemplate.createButton(button)
  return newTemplate
end

-- Delete existing template for an object
-- Return deleted template type or nil if there was none
SpellTemplates.DeleteTemplate = function(obj)
  for k,rTable in pairs(SpellTemplates.spawnedTemplates) do
    if rTable.obj == obj then
      rTable.ruler.destruct()
      local destType = rTable.type
      table.remove(SpellTemplates.spawnedTemplates, k)
      return destType
    end
  end
  return nil
end

-- Toggle template for an object
-- If a template of queried type exists, just delete it and return nil
-- If any other template exists, delete it (and spawn queried one), return new template ref
SpellTemplates.ToggleRuler = function(obj, templateType)
  local destType = SpellTemplates.DeleteTemplate(obj)
  if destType ~= templateType then
    return SpellTemplates.SpawnTemplate(obj, templateType)
  end
end
