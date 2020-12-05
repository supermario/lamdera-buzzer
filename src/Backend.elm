module Backend exposing (..)

import Dict
import Html
import Lamdera exposing (..)
import Task
import Time
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \m -> onConnect UserJoined
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { sessions = Dict.empty, order = 0 }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        UserJoined sessionId clientId ->
            case model.sessions |> Dict.get sessionId of
                Nothing ->
                    ( { model
                        | sessions =
                            model.sessions
                                |> Dict.insert sessionId
                                    { sessionId = sessionId
                                    , playerName = ""
                                    , buzz = Nothing
                                    }
                      }
                    , sendToFrontend sessionId NeedPlayerName
                    )

                Just session ->
                    ( model, sendToFrontend sessionId (ReadyToBuzz session.playerName) )

        BuzzedTime sessionId userTime serverTime ->
            requiringSession model
                sessionId
                (\session ->
                    let
                        buzz =
                            { playerName = session.playerName
                            , time = userTime
                            , received = serverTime
                            }
                    in
                    ( { model
                        | sessions =
                            model.sessions
                                |> Dict.insert sessionId
                                    { session
                                        | buzz =
                                            Just
                                                buzz
                                    }
                      }
                    , broadcast (BuzzResult buzz)
                    )
                )

        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        SetPlayerName playerName ->
            ( { model
                | sessions =
                    model.sessions
                        |> Dict.update sessionId (Maybe.map (\session -> { session | playerName = playerName }))
              }
            , sendToFrontend clientId (ReadyToBuzz playerName)
            )

        Buzzed time ->
            ( model, Time.now |> Task.perform (BuzzedTime sessionId time) )

        ResetBuzzers ->
            ( model, broadcast ResetBuzzers_ )

        NoOpToBackend ->
            ( model, Cmd.none )


requiringSession model sessionId func =
    case Dict.get sessionId model.sessions of
        Just session ->
            func session

        Nothing ->
            ( model, Cmd.none )
