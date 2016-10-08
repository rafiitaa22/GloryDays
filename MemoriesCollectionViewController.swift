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

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var memories: [URL] = []

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
        return cell
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
