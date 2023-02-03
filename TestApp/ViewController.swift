//
//  ViewController.swift
//  TestApp
//
//  Created by Glenn Posadas on 2/3/23.
//

import RxCocoa
import RxSwift
import UIKit

enum Status {
  case running
  case paused
  
  var titlePresentable: String {
    switch self {
    case .running:
      return "PAUSE"
    case .paused:
      return "START"
    }
  }
}

enum Mode: Int {
  case work
  case rest
}

let WORK_TIME = 10
let REST_TIME = 5

class ViewController: UIViewController {
  
  // MARK: -
  // MARK: Properties
  
  var _currentWork: Int = WORK_TIME
  var _lastWork: Int = WORK_TIME
  var _workStatus: Status = .paused
  
  var _currentRest: Int = REST_TIME
  var _lastRest: Int = REST_TIME
  var _restStatus: Status = .paused
  
  var _mode: Mode = .work
  
  var _workDisposeBag: DisposeBag?
  var _restDisposeBag: DisposeBag?
  
  @IBOutlet weak var timerLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var option: UISegmentedControl!
  
  // MARK: -
  // MARK: Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    updateValues()
    updateViews()
  }
  
  func countdownFormat(from seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
  }
  
  @IBAction func optionChanged(_ sender: UISegmentedControl) {
    guard let newMode = Mode(rawValue: sender.selectedSegmentIndex) else {
      return
    }
    _mode = newMode
    pauseWork()
    pauseRest()
    updateViews()
    updateValues()
  }
  
  @IBAction func startTapped(_ sender: UIButton) {
    switch _mode {
    case .work:
      if _workStatus == .paused {
        restartWork()
      } else {
        pauseWork()
      }
    case .rest:
      if _restStatus == .paused {
        restartRest()
      } else {
        pauseRest()
      }
    }
    
    updateViews()
  }
  
  private func pauseWork() {
    _workStatus = .paused
    _workDisposeBag = nil
  }
  
  private func pauseRest() {
    _restStatus = .paused
    _restDisposeBag = nil
  }
  
  private func updateViews() {
    switch _mode {
    case .work:
      startButton.setTitle(_workStatus.titlePresentable, for: .normal)
      view.backgroundColor = .systemPink
    case .rest:
      startButton.setTitle(_restStatus.titlePresentable, for: .normal)
      view.backgroundColor = .systemBlue
    }
  }
  
  private func updateValues() {
    switch _mode {
    case .work:
      timerLabel.text = countdownFormat(from: _currentWork)
    case .rest:
      timerLabel.text = countdownFormat(from: _currentRest)
    }
  }
  
  private func restartWork() {
    _mode = .work
    _workDisposeBag = DisposeBag()
    _workStatus = .running
    
    _lastWork = _currentWork
    
    Observable<Int>
      .timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
      .take(_currentWork + 1)
      .subscribe(onNext: { timePassed in
        self._currentWork = self._lastWork - timePassed
        self.updateValues()
      }, onCompleted: {
        self.option.selectedSegmentIndex = Mode.rest.rawValue
        self.optionChanged(self.option)
        self.startTapped(self.startButton)
      })
      .disposed(by: _workDisposeBag!)
  }
  
  private func restartRest() {
    _mode = .rest
    _restDisposeBag = DisposeBag()
    _restStatus = .running
    
    _lastRest = _currentRest

    Observable<Int>
      .timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
      .take(_currentRest + 1)
      .subscribe(onNext: { timePassed in
        self._currentRest = self._lastRest - timePassed
        self.updateValues()
      }, onCompleted: {
        self.option.selectedSegmentIndex = Mode.work.rawValue
        self.optionChanged(self.option)
        self.startTapped(self.startButton)
      })
      .disposed(by: _restDisposeBag!)
  }
}

