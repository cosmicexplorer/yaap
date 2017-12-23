# wow

> arg list -> (dict, list)

- assume invoked as: `COMMAND kwargs [--] args`
    - to be more specific: `COMMAND (--arg=value|--arg value|-a value)* (--)? (value)*`
- kwargs is a str/str map, args is a str list
- later options override earlier options

a moment of silence

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
        argsPrinted = JSON.stringify argsDashed

        super "The argument '-#{combinedNoDash}' is interpreted as the consecutive
        arguments #{argsPrinted}. The switch '-#{erroneousArg}' is in the middle of
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

    class ResolveArgNamesError extends Error
      constructor: (names) ->
        namesPrinted = JSON.stringify names
        super "The command line contained some arguments this program does not
        recognize. The invalid arguments were: #{namesPrinted}."

    shortArgToken = '[a-zA-Z]'
    longArgToken = '[a-zA-Z][a-zA-Z_-]*'

    class ArgumentParser
      constructor: (@kwargspec, @switchspec, opts = {}) ->
        {
          @throwOnUnregistered = yes
          @intermixArgsKwargs = yes
        } = opts
        @argspec =
          kwarg:
            shortMap: new Map
            longSet: null
          switch:
            shortMap: new Map
            longSet: null

        kwargConfig = @argspec.kwarg
        for arg in @kwargspec
          shortArg = arg[0]
          prevShort = kwargConfig.shortMap.get shortArg
          if prevShort?
            throw new OverlappingShortFormKeywordArgsError 'Arguments', @kwargspec, prevShort, arg
          else
            kwargConfig.shortMap.set shortArg, arg

        switchConfig = @argspec.switch
        for arg in @switchspec
          shortSwitch = arg[0]
          prevShortSwitch = switchConfig.shortMap.get shortSwitch
          if prevShortSwitch?
            throw new OverlappingShortFormKeywordArgsError 'Switches', @switchspec, prevShortSwitch, arg
          else
            switchConfig.shortMap.set shortSwitch, arg

        kwargConfig.longSet = new Set kwargConfig.shortMap.values()
        switchConfig.longSet = new Set switchConfig.shortMap.values()

      _insertKwarg: (annotated, kwargs, name, value, {short = no} = {}) ->
        kwargConfig = @argspec.kwarg
        resolvedName = switch
          when short then kwargConfig.shortMap.get name
          when kwargConfig.longSet.has name then name
          else null
        kwargs[resolvedName] = value if resolvedName?
        annotated.push {type: 'kwarg', short, name, resolvedName, value}

      _insertSwitch: (annotated, switches, name, {short = no} = {}) ->
        switchConfig = @argspec.switch
        resolvedName = switch
          when short then switchConfig.shortMap.get name
          when switchConfig.longSet.has name then name
          else null
        switches.push resolvedName if resolvedName?
        annotated.push {type: 'switch', short, name, resolvedName}

      _insertArg: (annotated, args, value) ->
        args.push value
        annotated.push {type: 'arg', value}

We require command lines to fit the following pseudo-EBNF grammar:

`COMMAND (--arg=value|--arg value|-a value|--switch|-s)* (--)? (value)*`

The `parse()` method executes a very ad-hoc handwritten parser. If a parser
generator could easily apply parsing to individual arguments on the command line
instead of just a string, it would reduce a lot of complexity here. An
alternative would be to bounce the command line to a string with correct shell
quoting for each argument, then parse that, but that's introducing needless
complexity.

      parse: (argv) ->
        args = []
        kwargs = {}
        switches = []

`annotated` is an array of json objects corresponding to parsed entities from `argv`. This is the hook by which a user can get into some more intense argument parsing with reflection/etc.

TODO(done): make the checking of maps and sets separate from the argument parsing, and make it optional to use (e.g. so people can handle unregistered arguments). Make it easy to get the benefits. Make it work *with* registered options too.

        annotated = []

Long and short arguments needing a value from the next argument in the list are
kept separate so we can make error messages specific to the argument actually
used on the command line -- there may be a better way to do this, and that's ok.

        previousLongArgName = null
        previousShortArgName = null
        for arg, i in argv
          if previousShortArgName?
            if arg is '--'
              throw new PreviousArgNoValueError "-#{previousShortArgName}"
            @_insertKwarg annotated, kwargs, previousShortArgName, arg, {short: yes}
            previousShortArgName = null
            continue

          if previousLongArgName?
            if arg is '--'
              throw new PreviousArgNoValueError "--#{previousLongArgName}"
            @_insertKwarg annotated, kwargs, previousLongArgName, arg
            previousLongArgName = null
            continue

          longArgWithValue = arg.match ///^--(#{longArgToken})=(.*)$///
          if longArgWithValue?
            [_, argName, argValue] = longArgWithValue
            @_insertKwarg annotated, kwargs, argName, argValue
            continue

          longArg = arg.match ///^--(#{longArgToken})$///
          if longArg?
            [_, argName] = longArg
            if @argspec.switch.longSet.has(argName)
              @_insertSwitch annotated, switches, argName
            else
              previousLongArgName = argName
            continue

          shortArg = arg.match ///^-((?:#{shortArgToken})+)$///
          if shortArg?
            [_, shortArguments] = shortArg
            [switchArgs..., maybeSwitchArg] = shortArguments.split ''

            for shortArgName in switchArgs
              if @argspec.switch.shortMap.has shortArgName
                @_insertSwitch annotated, switches, shortArgName, {short: yes}
              else
                throw new CombinedShortOptionsValueError shortArguments, shortArgName

            if @argspec.switch.shortMap.has maybeSwitchArg
              @_insertSwitch annotated, switches, maybeSwitchArg, {short: yes}
            else
              previousShortArgName = maybeSwitchArg
            continue

FIXME(fixed): it is the easiest thing in the world to only stop parsing args after a `--`, and to otherwise accept intermixed positional and keyword args. "CoffeeScript-style" argument parsing which enforces that one positional argument means the rest are also positional is better (although Pants is good too), but shouldn't be required.

          if arg is '--'
            argsAfterDashes = argv[i+1..]
            @_insertArg annotated, args, val for val in argsAfterDashes
            break
          else if @intermixArgsKwargs
            @_insertArg annotated, args, arg
            continue
          else
            argsIncludingCurrent = argv[i..]
            @_insertArg annotated, args, val for val in argsIncludingCurrent
            break

        if previousShortArgName?
          throw new PreviousArgNoValueError "-#{previousShortArgName}"

        if previousLongArgName?
          throw new PreviousArgNoValueError "--#{previousLongArgName}"

TODO(done): let's only throw after parsing all of the arguments -- we impose a specific structure on the argv our programs can handle so that we can get all the arguments without worrying about interpreting them too much, and then worry about validation.

        if @throwOnUnregistered
          unregisteredNames = annotated
            .filter(({resolvedName}) -> not resolvedName?)
            .map(({name}) -> name)
          if unregisteredNames.length > 0
            throw new ResolveArgNamesError unregisteredNames

        {args, kwargs, switches, annotated}

Example usage.

    Arguments = [
      'asdf'
      'bbbc'
      'wwer'
    ]

    Switches = [
      'verbose'
      'quiet'
    ]

    console.log new ArgumentParser(Arguments, Switches, {
      throwOnUnregistered: no
      intermixArgsKwargs: yes
    }).parse(process.argv[2..])

    module.exports = {ArgumentParser}
