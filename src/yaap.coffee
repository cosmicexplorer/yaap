###

arg list -> (dict, list)

- assume invoked as:
COMMAND kwargs [--] args

- kwargs is a Map[String -> String], args is a List[String]
- later options override earlier options

COMMAND (--arg=value|--arg value|-a value)* (--)? (value)*

###

# short_switches = [
#   'a'
#   'c'
# ]

# long_switches = [
#   'asdf'
# ]

args = []
kwargs = {}
# shortSwitches = []
# longSwitches = []

previousShortArgName = null

argv = process.argv[2..]

# shortToken = /[a-zA-Z]/
# longToken = /[a-zA-Z][a-zA-Z_-]+/

for arg, i in argv
  if previousShortArgName?
    kwargs[previousShortArgName] = arg
    previousShortArgName = null
    continue

  longKwArg = arg.match /^--([a-zA-Z][a-zA-Z_-]*)=(.*)$/
  if longKwArg?
    [_, argName, argValue] = longKwArg
    kwargs[argName] = argValue
    continue

  # longSwitch = arg.match /^--(#{})$/
  # if longSwitch?
  #   [_, argName]

  shortKwArg = arg.match /^-([a-zA-Z])$/
  if shortKwArg?
    [_, argName] = shortKwArg
    previousShortArgName = argName
    continue

  if arg is '--'
    args = argv[i+1..]
    break
  else
    args = argv[i..]
    break

if previousShortArgName?
  throw new Error "The last argument '-#{previousShortArgName}' requires a
  value after it in the argument list. If you meant to use this option, please
  provide an appropriate value (e.g. '-#{previousShortArgName} value')."

console.log 'process.argv:'
console.log process.argv
console.log 'args:'
console.log args
console.log 'kwargs:'
console.log kwargs
