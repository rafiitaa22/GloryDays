//
//  MemoriesCollectionViewController.swift
//  GloryDays
//
//  Created by Rafael Larrosa Espejo on 1/10/16.
//  Copyright © 2016 Rafael Larrosa Espejo. All rights reserved
//

import UIKit
import AVFoundation
import Photos
import Speech


private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate {
    
    var memories: [URL] = []
    
    var currentMemory: URL!
    
    var audioRecorder : AVAudioRecorder?
    var recordingURL : URL!
    
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.recordingURL = getDocumentsDirectory().appendingPathComponent("memory-recording.m4a") // falta el try con interrogante después del igual
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))
        
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.checkForGrantedPermissions()
    }
    
    func checkForGrantedPermissions(){
        let photosAuth: Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth: Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth: Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuth && recordingAuth && transcriptionAuth
        
        if !authorized{
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ShowTerms"){
                
                navigationController?.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func addImagePressed(){
        
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true, completion: nil)
        
    }
    
      func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addNewMemory(image: theImage)
            self.loadMemories()
            dismiss(animated: true)

        }else{
            
          print("algo ha ido mal")
            
        }
        
        
       
    }
    
    
    func addNewMemory(image: UIImage){
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        do{
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            if let jpegData = UIImageJPEGRepresentation(image, 80.0){
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            
            if let thumbnail = resizeImage(image: image, to: 200){
                let thumbPath =   getDocumentsDirectory().appendingPathComponent(thumbName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80.0){
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
            
        }catch{
            print("Ha fallado la escritura en el disco")
        }
    }
    //redimensión de la imagen
    
    func resizeImage(image: UIImage, to width: CGFloat) -> UIImage? {
        let scaleFactor = width/image.size.width
        
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext() // finalizamos la edición de la imagen
        
        return newImage
    }
    
    func loadMemories(){
        //eliminar todo lo que tengamos para no duplicar elementos
        self.memories.removeAll()
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
            return
        }// si no peta, sigue la rutina, es como el do try catch
        for file in files {
            let fileName = file.lastPathComponent
            if fileName.hasSuffix(".thumb"){
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                if let memoryPath = try? getDocumentsDirectory().appendingPathComponent(noExtension){
                    memories.append(memoryPath)
                }
            }
            
        }//
        
        collectionView?.reloadSections(IndexSet(integer: 1))
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func imageURL(for memory: URL) -> URL{
     return memory.appendingPathExtension("jpg") // falta el try!
    }
    
    func thumbnailURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL{
        return memory.appendingPathExtension("txt")
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 0{
            return 0
        }else{
        return self.memories.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        let memory = self.memories[indexPath.row]
        let memoryName = self.thumbnailURL(for: memory).path ?? ""
        let image = UIImage(contentsOfFile: memoryName)
        cell.imageView.image = image
        // Configure the cell
        if cell.gestureRecognizers == nil{
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
        }
    
        return cell
    }
    
    func memoryLongPressed(sender: UILongPressGestureRecognizer){//puede tener estado began o ended
       
        if sender.state == .began{
            //primero buscar que celda está presionada
            
            let cell = sender.view as! MemoryCell //si o si viene de una memorycell
            if let index = collectionView?.indexPath(for: cell){
                self.currentMemory = self.memories[index.row]
                self.startRecordingMemory()
                
            }
        }
        
        if sender.state == .ended{
           
            self.finishRecordingMemory(success: true)
        }
        
    }
    
    
    func startRecordingMemory(){
        audioPlayer?.stop()
        
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0, blue: 0, alpha: 1)
        let recordingSession = AVAudioSession.sharedInstance()
        do{
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord , with:.defaultToSpeaker)
            try recordingSession.setActive(true)
            let recordingSettings = [   AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                        AVSampleRateKey: 44100,
                                        AVNumberOfChannelsKey: 2,
                                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                
            ]
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            
        }catch{
            print("Ha habido un error:\(error)")
            finishRecordingMemory(success: false)
        }
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag{
            finishRecordingMemory(success: false)
        }
    }
    
    
    func finishRecordingMemory(success: Bool){
        collectionView?.backgroundColor = UIColor(red: 97.0/255.0, green: 86.0/255.0, blue: 110.0/255.0, alpha: 1)
        audioRecorder?.stop()
        if success{
            do{
                let memoryAudioURL = self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
                if(fileManager.fileExists(atPath: memoryAudioURL.path)){
                  try fileManager.removeItem(at: memoryAudioURL)
                }
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                self.transcriptAudioToText(memory: self.currentMemory)
            }catch let Error{
                print("Ha habido un error:\(Error)")
            }
        }else{
            
        }
        
        
    }
    
    func transcriptAudioToText(memory: URL){
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            guard let result = result else{
                print("Ha habido un error al transcribir el codigo")
                return
            }
            
            
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                do{
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                }catch{
                   print("Ha habdo un error al guardar la transcripción")
                }
            }
        })
        
        
        
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: 0, height: 50)
        } else {
            return CGSize.zero
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = self.memories[indexPath.row]
        let fileManager = FileManager.default //gestor de archivos por defecto
        do{
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            if fileManager.fileExists(atPath: audioName.path){
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
                
            }
            if fileManager.fileExists(atPath: transcriptionName.path){
                let contents = try String(contentsOf: transcriptionName)
                    print(contents)
                
            }

        }catch{
            print("error al cargar el audio a reproducir")
        }
    }
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
