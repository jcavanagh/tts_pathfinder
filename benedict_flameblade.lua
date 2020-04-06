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

function onLoad(save_state)
  -- Add commands to the table here
  my_commands = {
    attack = attack,
    perception = perception,

    fort = fort_save,
    reflex = reflex_save,
    will = will_save,

    test = test
  }

  -- keybinds
  keybinds = {
    fort_save, -- 1
    reflex_save, -- 2
    will_save, -- 3
    perception, -- 4
    attack -- 5
  }
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
    return string.sub(message, 2)
  end

  return nil
end

function execute_command(message)
  local command = parse_command(message)
  if my_commands[command] ~= nil then
    my_commands[command](player)
  else
    printToAll('Command not found')
  end
end

function onChat(message, player)
  if(player.steam_name == self.getDescription()) then
    execute_command(message)
  end
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
    for k, v in line:gmatch("([^%s]+):%s+([^%s]+)") do
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
