module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom
import Browser.Events as Browser
import Browser.Navigation as Nav
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Helpers exposing (..)
import Html
import Html.Attributes as Attr
import Json.Decode as Decode
import Lamdera exposing (..)
import Task
import Time
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.batch [ Browser.onKeyDown isSpacebar ]
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , playerName = ""
      , buzzes = Dict.empty
      , buzzed = False
      , mode = Joining
      }
    , Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Cmd.batch [ Nav.pushUrl model.key (Url.toString url) ]
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        ChangedNameInput s ->
            ( { model | playerName = s }, Cmd.none )

        SubmittedName ->
            ( model, sendToBackend (SetPlayerName model.playerName) )

        HitBuzzer ->
            ( model, Time.now |> Task.perform HitBuzzerTime )

        HitBuzzerTime time ->
            if not model.buzzed then
                ( { model | buzzed = True }, sendToBackend (Buzzed time) )

            else
                ( model, Cmd.none )

        HitResetBuzzers ->
            ( model, sendToBackend ResetBuzzers )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NeedPlayerName ->
            ( { model | mode = ChooseName }, Cmd.none )

        ReadyToBuzz playerName ->
            ( { model | mode = ShowBuzzer, playerName = playerName }, Cmd.none )

        BuzzResult buzz ->
            ( { model | buzzes = Dict.insert buzz.playerName buzz model.buzzes }, Cmd.none )

        ResetBuzzers_ ->
            ( { model | buzzes = Dict.empty, buzzed = False }
            , Task.attempt (\_ -> NoOpFrontendMsg) (Dom.blur "")
            )

        NoOpToFrontend ->
            ( model, Cmd.none )


view model =
    { title = ""
    , body =
        [ layout [ padding 20 ] <|
            case model.mode of
                Joining ->
                    column [] [ text "Joining" ]

                ChooseName ->
                    column [ spacing 10 ]
                        [ Input.text []
                            { onChange = ChangedNameInput
                            , text = model.playerName
                            , placeholder = Just (Input.placeholder [] (text "Desired name"))
                            , label = Input.labelAbove [] (text "Choose name:")
                            }
                        , buttonInactiveBy (model.playerName == "") SubmittedName "Submit"
                        ]

                ShowBuzzer ->
                    column [ spacing 30 ]
                        [ row [ spacing 20 ]
                            [ if model.buzzed then
                                buzzer "#ff0000" "Buzzed!"

                              else
                                buzzer "#00ff00" "Ready"
                            , model.buzzes
                                |> Dict.toList
                                |> List.indexedMap
                                    (\i ( k, v ) ->
                                        row [ spacing 10 ]
                                            [ text <| String.fromInt (i + 1)
                                            , text v.playerName
                                            , text <| Debug.toString v.time
                                            , text <| Debug.toString v.received
                                            ]
                                    )
                                |> column [ alignTop ]
                            ]
                        , button HitResetBuzzers "Reset All"
                        ]
        ]
    }


buzzer color label =
    el
        [ width (px 200)
        , height (px 200)
        , Border.rounded 100
        , Background.color <| fromHex color
        , Font.color <| fromHex "#000"
        ]
    <|
        el [ centerX, centerY ] <|
            text label


buttonInactiveBy condition msg label =
    if condition then
        el [ padding 10, Background.color <| fromHex "#eee", Font.color <| fromHex "#AAA" ] <| text label

    else
        button msg label


button msg label =
    Input.button
        [ padding 10
        , Background.color <| fromHex "#ccc"
        , Border.rounded 10
        ]
        { onPress = Just msg, label = text label }


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
