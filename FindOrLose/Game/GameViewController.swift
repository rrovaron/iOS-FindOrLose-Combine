//
//  GameViewController.swift
//  FindOrLose
//
//  Created by Rodrigo Rovaron on 07/23/21.
//

import UIKit
import Combine

class GameViewController: UIViewController {

  // MARK: - Variables
  var gameState: GameState = .stop {
    didSet {
      switch gameState {
        case .play:
          playGame()
        case .stop:
          stopGame()
      }
    }
  }

  var gameImages: [UIImage] = []
  var gameTimer: AnyCancellable?
  var gameLevel = 0
  var gameScore = 0
  
  var subscriptions: Set<AnyCancellable> = []

  // MARK: - Outlets

  @IBOutlet weak var gameStateButton: UIButton!
  @IBOutlet weak var gameScoreLabel: UILabel!
  @IBOutlet var gameImageView: [UIImageView]!
  @IBOutlet var gameImageButton: [UIButton]!
  @IBOutlet var gameImageLoader: [UIActivityIndicatorView]!

  // MARK: - View Controller Life Cycle
  override func viewDidLoad() {
    precondition(!UnsplashAPI.accessToken.isEmpty, "Please provide a valid Unsplash access token!")

    title = "Find or Lose"
    gameScoreLabel.text = "Score: \(gameScore)"
  }

  // MARK: - Game Actions

  @IBAction func playOrStopAction(sender: UIButton) {
    gameState = gameState == .play ? .stop : .play
  }

  @IBAction func imageButtonAction(sender: UIButton) {
    let selectedImages = gameImages.filter { $0 == gameImages[sender.tag] }
    
    if selectedImages.count == 1 {
      playGame()
    } else {
      gameState = .stop
    }
  }

  // MARK: - Game Functions

  func playGame() {
    gameTimer?.cancel()

    gameStateButton.setTitle("Stop", for: .normal)

    gameLevel += 1
    title = "Level: \(gameLevel)"

    gameScoreLabel.text = "Score: \(gameScore)"
    gameScore += 200

    resetImages()
    startLoaders()

    let firstImage = UnsplashAPI.randomImage()
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }
    
    let secondImage = UnsplashAPI.randomImage()
      .flatMap { randomImageResponse in
        ImageDownloader.download(url: randomImageResponse.urls.regular)
      }
    
    firstImage.zip(secondImage)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { [unowned self] completion in
        switch completion {
        case .finished: break
        case .failure(let error):
          print("Error: \(error)")
          self.gameState = .stop
        }
      }, receiveValue: { [unowned self] first, second in
        
      self.gameTimer = Timer.publish(every: 0.1, on: RunLoop.main, in: .common)
        .autoconnect()
        .sink { [unowned self] _ in
          self.gameScoreLabel.text = "Score \(self.gameScore)"
          self.gameScore -= 10
          
          if self.gameScore < 0 {
            self.gameScore = 0
            self.gameTimer?.cancel()
          }
        }
        
        self.gameImages = [first, second, second, second].shuffled()
        
        self.stopLoaders()
        self.setImages()
      })
      .store(in: &subscriptions)

  }

  func stopGame() {
    subscriptions.forEach { $0.cancel() }
    gameTimer?.cancel()

    gameStateButton.setTitle("Play", for: .normal)

    title = "Find or Lose"

    gameLevel = 0

    gameScore = 0
    gameScoreLabel.text = "Score: \(gameScore)"

    stopLoaders()
    resetImages()
  }

  // MARK: - UI Functions

  func setImages() {
    if gameImages.count == 4 {
      for (index, gameImage) in gameImages.enumerated() {
        gameImageView[index].image = gameImage
      }
    }
  }

  func resetImages() {
    subscriptions = []
    gameImages = []
    gameImageView.forEach { $0.image = nil }
  }

  func startLoaders() {
    gameImageLoader.forEach { $0.startAnimating() }
  }

  func stopLoaders() {
    gameImageLoader.forEach { $0.stopAnimating() }
  }
}
