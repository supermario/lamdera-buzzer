module Types exposing (..)

import Dict exposing (Dict)
import Lamdera exposing (..)
import Page exposing (..)
import Time
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , page : Page
    , playerName : String
    , buzzed : Bool
    , buzzes : Dict String Buzz
    }


type alias BackendModel =
    { sessions : Dict SessionId Session
    , order : Int
    }


type alias Session =
    { sessionId : SessionId
    , playerName : String
    , buzz : Maybe Buzz
    , pingStart : Time.Posix
    , latency : Int
    }


type alias Buzz =
    { playerName : String
    , time : Time.Posix
    , received : Time.Posix
    , latency : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | ChangedNameInput String
    | SubmittedName
    | HitBuzzer
    | HitBuzzerTime Time.Posix
    | HitResetBuzzers
    | NoOpFrontendMsg


type ToBackend
    = GotPong
    | SetPlayerName String
    | Buzzed Time.Posix
    | ResetBuzzers
    | NoOpToBackend


type BackendMsg
    = UserJoined SessionId ClientId
    | StartPing SessionId Time.Posix
    | EndPing SessionId Time.Posix
    | BuzzedTime SessionId Time.Posix Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = NeedPlayerName
    | GotPing
    | ReadyToBuzz String
    | BuzzResult Buzz
    | ResetBuzzers_
    | NoOpToFrontend
