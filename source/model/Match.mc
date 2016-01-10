using Toybox.System as Sys;
using Toybox.Time as Time;

class Match {

	const MAXIMUM_POINTS = 21;
	const ABSOLUTE_MAXIMUM_POINTS = 30;

	hidden var type; //type of the match, :single or :double
	hidden var beginner; //store the beginner of the match, :player_1 or :player_2

	hidden var rallies; //array of all rallies

	hidden var scores; //dictionnary containing players current scores
	hidden var server; //in double, true if the player 1 (watch carrier) is currently the server

	var startTime;
	var stopTime;

	var listener;

	function initialize(state) {
		reset();
		restore(state);
	}

	function restore(state) {
		if(state != null) {
			//rallies = state.get(:match_rallies);
			//beginner = state.get("match_beginner");
			//scores = state.get("match_scores");
		}
	}

	function save(state) {
		//state.put("match_rallies", rallies);
		//state.put("match_beginner", beginner);
		//state.put("match_scores", scores);
	}

	function begin(player) {
		beginner = player;
		startTime = Time.now();
		if(listener != null && listener has :onMatchBegin) {
			listener.onMatchBegin();
		}
	}

	hidden function end(winner) {
		stopTime = Time.now();
		if(listener != null && listener has :onMatchEnd) {
			listener.onMatchEnd(winner);
		}
	}

	function score(player) {
		if(hasBegun()) {
			//in double, change server if player 1 (watch carrier) team regain service
			if(type == :double) {
				if(rallies.last() == :player_2 && player == :player_1) {
					server = !server;
				}
			}
			rallies.push(player);
			scores[player]++;
			//detect if match has a winner
			var winner = getWinner();
			if(winner != null) {
				end(winner);
			}
		}
	}

	function undo() {
		stopTime = null;
		if(rallies.size() > 0) {
			var rally = rallies.pop();
			//in double, change server if player 1 (watch carrier) team regain service
			if(type == :double) {
				if(rally == :player_2 && rallies.last() == :player_1) {
					server = !server;
				}
			}
			scores[rally]--;
		}
	}

	function reset() {
		rallies = new List();
		type = null;
		beginner = null;
		server = true;
		scores = {:player_1 => 0, :player_2 => 0};
		startTime = null;
		stopTime = null;
	}

	function getRalliesNumber() {
		return rallies.size();
	}

	function getDuration() {
		if(startTime == null) {
			return null;
		}
		var time = stopTime != null ? stopTime : Time.now();
		return time.subtract(startTime);
	}

	function hasType() {
		return type != null;
	}

	function setType(match_type) {
		type = match_type;
	}

	function getType() {
		return type;
	}

	function setBeginner(match_beginner) {
		beginner = match_beginner;
	}

	function hasBegun() {
		return beginner != null;
	}

	function hasEnded() {
		return getWinner() != null;
	}

	function getScore(player) {
		return scores[player];
	}

	function getWinner() {
		var scorePlayer1 = getScore(:player_1);
		var scorePlayer2 = getScore(:player_2);
		if(scorePlayer1 >= ABSOLUTE_MAXIMUM_POINTS || scorePlayer1 >= MAXIMUM_POINTS && (scorePlayer1 - scorePlayer2) > 1) {
			return :player_1;
		}
		if(scorePlayer2 >= ABSOLUTE_MAXIMUM_POINTS || scorePlayer2 >= MAXIMUM_POINTS && (scorePlayer2 - scorePlayer1) > 1) {
			return :player_2;
		}
		return null;
	}

	function getServer() {
		//beginning of the match
		if(rallies.isEmpty()) {
			return beginner;
		}
		//last team who score
		return rallies.last();
	}

	function getHighlightedCorner() {
		var server = getServer();
		var server_score = getScore(server);
		//player 1 serves from corner 2 or 3
		if(server == :player_1) {
			return 3 - server_score % 2;
		}
		//player 2 serves from corner 0 or 1
		return server_score % 2;
	}

	//methods used from perspective of player 1 (watch carrier)
	hidden function getPlayerTeamIsServer() {
		return getServer() == :player_1;
	}

	function getPlayerCorner() {
		if(getPlayerTeamIsServer()) {
			Sys.println("player team is server");
			var highlighted_corner = getHighlightedCorner();
			if(server) {
				Sys.println("player is server");
				return highlighted_corner;
			}
			//return other corner
			return highlighted_corner == 2 ? 3 : 2;
		}
		return null;
	}

}
