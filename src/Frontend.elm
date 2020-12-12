module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Dom as Dom
import Browser.Events as Browser
import Browser.Navigation as Nav
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input as Input
import Helpers exposing (..)
import Html
import Html.Attributes as Attr
import Lamdera exposing (..)
import Page exposing (..)
import Round
import Task
import Time
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , page = Page.pathToPage url
      , playerName = ""
      , buzzed = False
      , buzzes = Dict.empty
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
            let
                page =
                    Page.pathToPage url
            in
            if model.page /= page then
                ( { model | page = page }
                , Cmd.none
                )

            else
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
        GotPing ->
            ( model, sendToBackend GotPong )

        NeedPlayerName ->
            ( { model | page = ChooseName }, Cmd.none )

        ReadyToBuzz playerName ->
            if model.page /= Hosting then
                ( { model | page = Buzzing, playerName = playerName }, Cmd.none )

            else
                ( { model | playerName = playerName }, Cmd.none )

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
        [ manualCss
        , layout [ fontInter, padding 20 ] <|
            case model.page of
                Joining ->
                    column [] [ text "Joining" ]

                ChooseName ->
                    column [ spacing 10, width (fill |> maximum 400), centerX ]
                        [ Input.text [ Border.rounded 10, centerX ]
                            { onChange = ChangedNameInput
                            , text = model.playerName
                            , placeholder = Just (Input.placeholder [] (text "Desired name"))
                            , label = Input.labelAbove [] (text "Choose name:")
                            }
                        , buttonInactiveBy [ centerX ] (model.playerName == "") SubmittedName "Submit"
                        ]

                Buzzing ->
                    column [ spacing 30, width fill ]
                        [ if model.buzzed then
                            buzzer "#ff0000" "Buzzed!"

                          else
                            buzzer "#00ff00" "Ready"
                        , listBuzzes model
                        ]

                Hosting ->
                    column [ spacing 30, width fill ]
                        [ heading "Hosting"
                        , listBuzzes model
                        , button [ centerX ] HitResetBuzzers "Reset All"
                        ]
        ]
    }


listBuzzes model =
    let
        buzzes =
            model.buzzes
                |> Dict.toList
                |> List.sortBy (\( k, v ) -> Time.posixToMillis v.received - v.latency)

        firstMaybe =
            buzzes |> List.head |> Maybe.map Tuple.second
    in
    case firstMaybe of
        Nothing ->
            el [ centerX ] <| text "No buzzes yet..."

        Just first ->
            Element.indexedTable [ centerX, width (fill |> maximum 600), spacing 10 ]
                { data = buzzes |> List.map Tuple.second
                , columns =
                    [ { header = text "Pos"
                      , width = fill
                      , view =
                            \i buzz ->
                                text <| String.fromInt (i + 1)
                      }
                    , { header = text "Name"
                      , width = fill
                      , view =
                            \i buzz ->
                                text buzz.playerName
                      }
                    , { header = text "Diff"
                      , width = fill
                      , view =
                            \i buzz ->
                                text <| "+" ++ (format <| diff buzz.received first.received)
                      }
                    , { header = text "Latency"
                      , width = fill
                      , view =
                            \i buzz ->
                                text <| format <| buzz.latency
                      }
                    ]
                }


format ms =
    if ms < 1000 then
        String.fromInt ms ++ "ms"

    else if ms < 60000 then
        (Round.round 2 <| (toFloat ms / 1000)) ++ "s"

    else
        "more than 1 minute"


diff t1 t2 =
    Time.posixToMillis t1 - Time.posixToMillis t2


buzzer color label =
    el
        [ width (px 200)
        , height (px 200)
        , Border.rounded 100
        , Background.color <| fromHex color
        , Font.color <| fromHex "#000"
        , onClick HitBuzzer
        , centerX
        ]
    <|
        el [ centerX, centerY ] <|
            text label


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
