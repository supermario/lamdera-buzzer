module Evergreen.V1.Types exposing (..)

import Dict
import Lamdera
import Time
import Url


type alias Buzz = 
    { playerName : String
    , time : Time.Posix
    , received : Time.Posix
    }


type Mode
    = Joining
    | ChooseName
    | ShowBuzzer


type alias FrontendModel =
    { key : Lamdera.Key
    , playerName : String
    , buzzes : (Dict.Dict String Buzz)
    , buzzed : Bool
    , mode : Mode
    }


type alias Session = 
    { sessionId : Lamdera.SessionId
    , playerName : String
    , buzz : (Maybe Buzz)
    }


type alias BackendModel =
    { sessions : (Dict.Dict Lamdera.SessionId Session)
    , order : Int
    }


type FrontendMsg
    = UrlClicked Lamdera.UrlRequest
    | UrlChanged Url.Url
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
    = UserJoined Lamdera.SessionId Lamdera.ClientId
    | BuzzedTime Lamdera.SessionId Time.Posix Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = NeedPlayerName
    | ReadyToBuzz String
    | BuzzResult Buzz
    | ResetBuzzers_
    | NoOpToFrontend