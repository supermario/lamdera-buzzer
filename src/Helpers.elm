module Helpers exposing (..)

import Color exposing (rgb)
import Color.Convert exposing (hexToColor)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Json.Decode as Decode
import Types exposing (..)


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


heading str =
    el [ Font.bold, Font.size 22, centerX ] <| text str


buttonInactiveBy attrs condition msg label =
    if condition then
        el
            ([ padding 10
             , Background.color <| fromHex "#eee"
             , Font.color <| fromHex "#AAA"
             , Border.rounded 10
             ]
                ++ attrs
            )
        <|
            text label

    else
        button attrs msg label


button attrs msg label =
    Input.button
        ([ padding 10
         , Background.color <| fromHex "#ccc"
         , Border.rounded 10
         ]
            ++ attrs
        )
        { onPress = Just msg, label = text label }


manualCss =
    Html.node "style"
        []
        [ Html.text <|
            """
          @import url('https://rsms.me/inter/inter.css');
          html { font-family: 'Inter', sans-serif; }
          @supports (font-variation-settings: normal) {
            html { font-family: 'Inter var', sans-serif; }
          }
            """
        ]


fontInter =
    Font.family
        [ Font.typeface "Inter"
        , Font.sansSerif
        ]


isSpacebar : Decode.Decoder FrontendMsg
isSpacebar =
    keyDecoder
        |> Decode.andThen
            (\v ->
                if v == " " then
                    Decode.succeed HitBuzzer

                else
                    Decode.succeed NoOpFrontendMsg
            )


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
