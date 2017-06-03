//
//  ViewController.swift
//  Jarvis
//
//  Created by Hien Nguyen on 6/3/17.
//  Copyright © 2017 hienn. All rights reserved.
//

import UIKit
import Speech
import Alamofire
import AlamofireObjectMapper

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var dataView: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var lunchMenu: [LunchMenu]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
            stopRecording();
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func processText() {
        let message = textView.text;
        //let message = "show me the menu of Friday"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer BYWECCXFLFH43NODXM5OFIIRSZJWHNYM",
            ]
        let requestUrl = "https://api.wit.ai/message"
        let parameters: [String: String] = [
            "v" : "20170307",
            "q" : message!
        ]
        
        Alamofire.request(requestUrl, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseObject { (response: DataResponse<WitResponse>) in
            
            let witResponse = response.result.value
            self.processWitReturn(intent: (witResponse?.entities?.intents?[0].value!)!, witResponse: witResponse!)
        }
    }
    
    func processIntent(intent: String, witResponse: WitResponse) {
        switch intent {
        case "menu_all_get":
            print("menu_get_all")
            self.processGetAllMenu()
        case "menu_get":
            print("menu_get")
            self.processGetMenu(date: (witResponse.entities?.witDateTime?[0].values?[0].value)!)
        default:
            print("do nothing")
        }
    }
    
    func processWitReturn(intent: String, witResponse: WitResponse)  {
        if (lunchMenu == nil) {
            //let requestUrl = "https://doc-14-1k-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/2r2bqvhemh7q6ajq5gq5d1fqolo51rcv/1496304000000/16116592902483604091/*/0B5D0p6Uc-Nwlenh0Q2xuMDA3UFE?e=download"
            let requestUrl = "http://192.168.99.37/lunch.json"
            
            Alamofire.request(requestUrl).responseArray { (response: DataResponse<[LunchMenu]>) in
                print(response.result.value ?? "a")
                self.lunchMenu = response.result.value
                self.processIntent(intent: intent, witResponse: witResponse)
            }
        } else {
            processIntent(intent: intent, witResponse: witResponse)
        }
    }
    
    func processGetAllMenu() {
        var content = ""
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.short
        dateformatter.timeStyle = DateFormatter.Style.short
        print (lunchMenu!)
        
        for menus in lunchMenu! {
            content += "\n" + (dateformatter.string(from: menus.date! as Date)) + "\n"
            var index = 0;
            for menu in menus.menu! {
                index += 1;
                content += "\(index).\(menu.food!)\n"
            }
            content += "--------------------------------\n"
        }
        
        dataView.text = content;
    }
    
    func processGetMenu(date: Date) {
        var content = ""
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.short
        dateformatter.timeStyle = DateFormatter.Style.short
        
        for menus in lunchMenu! {
            if (date == menus.date!) {
                content += "\n" + (dateformatter.string(from: menus.date! as Date)) + "\n"
                var index = 0;
                for menu in menus.menu! {
                    index += 1;
                    content += "\(index).\(menu.food!)\n"
                }
                content += "--------------------------------\n"
            }
        }
        dataView.text = content;
    }
    
    func stopRecording() {
        dataView.text = "processing...";
        processText();
    }
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}


