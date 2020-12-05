module Helpers exposing (..)

import Color exposing (rgb)
import Color.Convert exposing (hexToColor)
import Element exposing (..)


fromHex : String -> Color
fromHex str =
    case hexToColor str of
        Ok col ->
            let
                x =
                    Color.toRgba col
            in
            Element.rgba x.red x.green x.blue x.alpha

        Err _ ->
            Element.rgb 255 0 0
