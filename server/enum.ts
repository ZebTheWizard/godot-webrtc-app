export enum message {
  ID,
	ERROR,
	LOGIN,
	LOGIN_SUCCESS,
	SIGNUP,
	SIGNUP_SUCCESS,
	MATCH_CREATE,
	MATCH_CREATE_SUCCESS,
	MATCH_LIST,
	LOBBY,
	MATCH_JOIN,
	MATCH_CONNECTED,
	MATCH_LEAVE,
	MATCH_DISCONNECTED,
	MATCH_START,
	WEBRTC_OFFER,
	WEBRTC_ANSWER,
	WEBRTC_EXCHANGE
}

export enum match_status {
  MATCHING = 'matching',
  IN_PROGRESS = 'playing'
}

export enum match_type {
  FFA = "free-for-all"
}

export enum map {
  DEFAULT = "uid://ynqly5lsqmk4"
}
