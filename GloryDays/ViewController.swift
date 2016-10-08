//
//  ViewController.swift
//  GloryDays
//
//  Created by Rafael Larrosa Espejo on 1/10/16.
//  Copyright © 2016 Rafael Larrosa Espejo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech



class ViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func askForPermissions(_ sender: UIButton) {
        self.askForPhotosPermissions()
    }
    
    func askForPhotosPermissions(){
        PHPhotoLibrary.requestAuthorization { [unowned self](authStatus) in
            DispatchQueue.main.async { // este dispatchqueue que rodea todo el if, lo manda al hilo principal del main
                if authStatus == .authorized{
                    self.askForRecordPermissions()
                }else{
                    self.infoLabel.text = "Nos has denegado el permiso de fotos. Por favor, actívalo en los Ajustes de tu dispositivo para continuar."
                }
            }
        }
    }
    
    func askForRecordPermissions(){
        AVAudioSession.sharedInstance().requestRecordPermission { (allowed) in
            DispatchQueue.main.async {
                if allowed{
                    self.askForTranscriptionPermissions()
                }else{
                    self.infoLabel.text = "Nos has denegado los permisos de grabación de audio. Por favor, actívalo en los Ajustes de tu dispositivo para continuar."
                }
            }
        }
    }
    
    func askForTranscriptionPermissions(){
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized{
                    self.authorizationCompleted()
                }else{
                    self.infoLabel.text = "Nos has denegado los permisos de transcripción de texto. Por favor, actívalos en los Ajustes de tu dispositivo para continuar."
                    
                }
            }
        }
    }
    
    func authorizationCompleted(){
        dismiss(animated: true, completion: nil)
    }
    
}

