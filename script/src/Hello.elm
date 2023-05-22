module Hello exposing (run)

import BackendTask
import BackendTask.Http
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import Dict
import FatalError exposing (FatalError)
import Json.Decode exposing (Decoder)
import Pages.Script as Script exposing (Script)


type alias PackageDescription =
    { name : String, exposedModules : List String }


packageDescriptionDecoder : Decoder PackageDescription
packageDescriptionDecoder =
    Json.Decode.map2 PackageDescription
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "exposed-modules" exposedModulesDecoder)


exposedModulesDecoder : Decoder (List String)
exposedModulesDecoder =
    Json.Decode.oneOf
        [ Json.Decode.list Json.Decode.string
        , Json.Decode.dict (Json.Decode.list Json.Decode.string)
            |> Json.Decode.map Dict.values
            |> Json.Decode.map List.concat
        ]


programConfig : Program.Config String
programConfig =
    Program.config
        |> Program.add
            (OptionsParser.build identity
                |> OptionsParser.with (Option.requiredPositionalArg "Module.Name")
            )


getPackageDescription : String -> BackendTask.BackendTask FatalError PackageDescription
getPackageDescription packageName =
    BackendTask.Http.getJson
        ("https://package.elm-lang.org/packages/" ++ packageName ++ "/latest/elm.json")
        packageDescriptionDecoder
        |> BackendTask.allowFatal


run : Script
run =
    Script.withCliOptions programConfig
        (\moduleName ->
            getPackageDescription moduleName
                |> BackendTask.andThen (\s -> Script.log (Debug.toString s))
        )
