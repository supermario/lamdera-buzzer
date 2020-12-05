module Types exposing (..)

import Dict exposing (Dict)
import Lamdera exposing (..)
import Time
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , playerName : String
    , buzzes : Dict String Buzz
    , buzzed : Bool
    , mode : Mode
    }


type Mode
    = Joining
    | ChooseName
    | ShowBuzzer


type alias BackendModel =
    { sessions : Dict SessionId Session
    , order : Int
    }


type alias Buzz =
    { playerName : String
    , time : Time.Posix
    , received : Time.Posix
    }


type alias Session =
    { sessionId : SessionId
    , playerName : String
    , buzz : Maybe Buzz
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
    = SetPlayerName String
    | Buzzed Time.Posix
    | ResetBuzzers
    | NoOpToBackend


type BackendMsg
    = UserJoined SessionId ClientId
    | BuzzedTime SessionId Time.Posix Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = NeedPlayerName
    | ReadyToBuzz String
    | BuzzResult Buzz
    | ResetBuzzers_
    | NoOpToFrontend
