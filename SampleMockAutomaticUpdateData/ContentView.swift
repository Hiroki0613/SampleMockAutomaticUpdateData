//
//  ContentView.swift
//  SampleMockAutomaticUpdateData
//
//  Created by 近藤宏輝 on 2023/01/01.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct GameState {
    let homeScore: Int
    let awayScore: Int
    let scoringTeamName: String
    let lastAction: String
    
    var winningTeamName: String {
        homeScore > awayScore ? "ホームチーム" : "敵チーム"
    }
}

struct Team {
    let name: String
    let players: [String]
}

protocol GameSimulatorDelegate: AnyObject {
    func didUpdate(gameState: GameState)
    func didCompleteGame()
}

final class GameSimulator {
    var homeTeam: Team
    var awayTeam: Team
    var homeScore: Int = 0
    var awayScore: Int = 0
    var homePossession = true
    
    var scoringTeam: Team {
        homePossession ? homeTeam : awayTeam
    }
    
    var possessionCount = 0
    var timer: Timer?
    
    weak var delegate: GameSimulatorDelegate?
    
    init() {
        self.homeTeam = Team(
            name: "チーム東京",
            players: [
                "新宿",
                "渋谷",
                "恵比寿",
                "目黒",
                "五反田"
            ]
        )
        self.awayTeam = Team(
            name: "チーム大阪",
            players: [
                "大阪",
                "鶴橋",
                "桃谷",
                "福島",
                "天満",
                "天王寺"
            ]
        )
    }
    
    func start() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(runGameSimulator), userInfo: nil, repeats: true)
    }
    
    @objc func runGameSimulator() {
        guard let delegate = delegate else { return }
        delegate.didUpdate(gameState: progressGame())
        guard possessionCount <= 120 else {
            delegate.didCompleteGame()
            return
        }
        possessionCount = possessionCount + 1
    }
    
    func end() {
        delegate?.didUpdate(gameState: endGame())
    }
    
    func reset() {
        timer?.invalidate()
        homeScore = 0
        awayScore = 0
        possessionCount = 0
        homePossession = true
    }
    
    func progressGame() -> GameState {
        let pointScored = Int.random(in: 0...3)
        homePossession ? (homeScore = homeScore + pointScored) : (awayScore = awayScore + pointScored)
        let lastAction = createLastActionString(scoringTeam: scoringTeam, pointScored: pointScored)
        let scoringTeamName = scoringTeam.name
        homePossession.toggle()
        return GameState(
            homeScore: homeScore,
            awayScore: awayScore,
            scoringTeamName: scoringTeamName,
            lastAction: lastAction
        )
    }
    
    func endGame() -> GameState {
        let finalHomeScore = homeScore
        let finalAwayScore = awayScore
        let winningTeam = finalHomeScore > finalAwayScore ? homeTeam : awayTeam
        reset()
        return GameState(
            homeScore: finalHomeScore,
            awayScore: finalAwayScore,
            scoringTeamName: winningTeam.name,
            lastAction: "The game has ended. \(winningTeam.name.capitalized) win!")
    }
    
    func createLastActionString(scoringTeam: Team, pointScored: Int) -> String {
        let scoringPlayer = scoringTeam.players.randomElement() ?? "Player"
        
        switch pointScored {
        case 0:
            return scoringPlayer + " " + "missed a shot"
        case 1:
            return scoringPlayer + " " + "made 1 of 2 free throws"
        case 2:
            return scoringPlayer + " " + "lays it in for 2"
        case 3:
            return scoringPlayer + " " + "drains a 3"
        default:
            return scoringPlayer + " " + "had a 4 point play!"
        }
    }
}

final class GameModel: ObservableObject, GameSimulatorDelegate {
    
    @Published var gameState = GameState(
        homeScore: 0,
        awayScore: 0,
        scoringTeamName: "",
        lastAction: ""
    )
    let simulator = GameSimulator()
    init() {
        simulator.delegate = self
    }
    func didUpdate(gameState: GameState) {
        self.gameState = gameState
    }
    func didCompleteGame() {
    }
}
