module Page exposing (..)

import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query as Query


type Page
    = Joining
    | ChooseName
    | Buzzing
    | Hosting


pageToPath : Page -> String
pageToPath page =
    case page of
        Joining ->
            "/joining"

        ChooseName ->
            "/name"

        Buzzing ->
            "/buzz"

        Hosting ->
            "/host"


pathToPage : Url -> Page
pathToPage url =
    let
        match =
            [ map Joining (s "joining")
            , map ChooseName (s "name")
            , map Buzzing (s "buzz")
            , map Hosting (s "host")
            ]
                |> oneOf
                |> (\parser -> parse parser url)
                |> Maybe.withDefault Joining
    in
    match
