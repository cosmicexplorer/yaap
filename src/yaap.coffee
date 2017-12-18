###

arg list -> (dict, list)

- assume invoked as:
COMMAND kwargs [--] args

- kwargs is a Map[String -> String], args is a List[String]
- later options override earlier options

COMMAND (--arg=value|--arg value|-a value)* (--)? (value)*

###

class OverlappingShortFormKeywordArgsError extends Error
  constructor: (argSetDescription, argArr, firstLong, secondLong) ->
    shortArg = firstLong[0]

    super "The given '#{argSetDescription}' array has two long form options
    '--#{firstLong}' and '--#{secondLong}', which share the same first letter
    '#{shortArg}'. This program uses the first letter of a long-form argument
    (e.g. '--#{firstLong}') to form the short-form of the argument
    '-#{shortArg}', so '--#{firstLong}' and '--#{secondLong}' cannot be used
    together. This is a bug.\n\nThe full array is: #{JSON.stringify(argArr)}."

class CombinedShortOptionsValueError extends Error
  constructor: (combinedNoDash, erroneousArg) ->
    argsDashed = combinedNoDash.split('').map (x) -> "-#{x}"

    super "The argument '-#{combinedNoDash}' is interpreted as the consecutive
    arguments #{argsDashed}. The switch '-#{erroneousArg}' is in the middle of
    the interpreted arguments, but that argument is not a switch. It requires a
    value (e.g. '-#{erroneousArg} value'). Move '#{erroneousArg}' to the end of
    the combined arguments, or separate it into a separate '-#{erroneousArg}'
    short keyword argument."

class PreviousArgNoValueError extends Error
  constructor: (argWithDashes) ->
    super "The last keyword argument '#{argWithDashes}' is not a switch. It
    requires a value after it in the argument list (e.g. '#{argWithDashes}
    value'). If you meant to use this option, please provide an appropriate
    value."

shortArgToken = '[a-zA-Z]'
longArgToken = '[a-zA-Z][a-zA-Z_-]*'

class ArgumentParser
  constructor: (kwargspec, switchspec) ->
    @shortKwargMap = new Map
    for arg in kwargspec
      shortArg = arg[0]
      prevShort = @shortKwargMap.get(shortArg)
      if prevShort?
        throw new OverlappingShortFormKeywordArgsError 'Arguments', kwargspec, prevShort, arg
      else
        @shortKwargMap.set(shortArg, arg)

    @shortSwitchMap = new Map
    for arg in switchspec
      shortSwitch = arg[0]
      prevShortSwitch = @shortSwitchMap.get(shortSwitch)
      if prevShortSwitch?
        throw new OverlappingShortFormKeywordArgsError 'Switches', switchspec, prevShortSwitch, arg
      else
        @shortSwitchMap.set(shortSwitch, arg)

    @longSwitchSet = new Set @shortSwitchMap.values()

  parse: (argv) ->
    args = []
    kwargs = {}
    switches = []

    # prev long/short args are kept separate so we can make error messages
    # specific to the argument actually used on the command line -- there may be
    # a better way to do this
    previousLongArgName = null
    previousShortArgName = null
    for arg, i in argv
      if previousShortArgName?
        if arg is '--'
          throw new PreviousArgNoValueError "-#{previousShortArgName}"
        longForm = @shortKwargMap.get previousShortArgName
        kwargs[longForm] = arg
        previousShortArgName = null
        continue

      if previousLongArgName?
        if arg is '--'
          throw new PreviousArgNoValueError "--#{previousLongArgName}"
        kwargs[previousLongArgName] = arg
        previousLongArgName = null
        continue

      longArgWithValue = arg.match ///^--(#{longArgToken})=(.*)$///
      if longArgWithValue?
        [_, argName, argValue] = longArgWithValue
        kwargs[argName] = argValue
        continue

      longArg = arg.match ///^--(#{longArgToken})$///
      if longArg?
        [_, argName] = longArg
        if @longSwitchSet.has(argName)
          switches.push argName
        else
          previousLongArgName = argName
        continue

      shortArg = arg.match ///^-((?:#{shortArgToken})+)$///
      if shortArg?
        [_, shortArguments] = shortArg
        [switchArgs..., maybeSwitchArg] = shortArguments.split ''

        for shortArgName in switchArgs
          longForm = @shortSwitchMap.get shortArgName
          if longForm?
            switches.push shortArgName
          else
            throw new CombinedShortOptionsValueError shortArguments, shortArgName

        maybeSwitchLong = @shortSwitchMap.get maybeSwitchArg
        if maybeSwitchLong?
          switches.push maybeSwitchLong
        else
          previousShortArgName = maybeSwitchArg
        continue

      if arg is '--'
        args = argv[i+1..]
        break
      else
        args = argv[i..]
        break

    if previousShortArgName?
      throw new PreviousArgNoValueError "-#{previousShortArgName}"

    if previousLongArgName?
      throw new PreviousArgNoValueError "--#{previousLongArgName}"

    {args, kwargs, switches}

Arguments = [
  'asdf'
  'bbbc'
  'wwer'
]

Switches = [
  'verbose'
  'quiet'
]

console.log new ArgumentParser(Arguments, Switches).parse(process.argv[2..])

module.exports = {ArgumentParser}
