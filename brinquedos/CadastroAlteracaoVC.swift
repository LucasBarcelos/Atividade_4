//
//  CadastroAlteracaoVC.swift
//  brinquedos
//
//  Created by Lucas Barcelos on 02/01/22.
//

import UIKit
import Foundation
import FirebaseFirestore

class CadastroAlteracaoVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var nomeBrinquedoTxt: UITextField?
    @IBOutlet weak var nomeDoadorTxt: UITextField?
    @IBOutlet weak var enderecoTxt: UITextField?
    @IBOutlet weak var prefixoTxt: UITextField?
    @IBOutlet weak var telefoneTxt: UITextField?
    @IBOutlet weak var conservacaoControl: UISegmentedControl!
    
    // MARK: - Properties
    var navigationTitle = ""
    var conservacao = ""
    var brinquedo = ""
    var endereco = ""
    var telefone = ""
    var doador = ""
    var id = ""
    var novoBrinquedo = false
    
    // Firestore
    let collection = "brinquedoLista"
    var brinquedoLista: [BrinquedoItem] = []
    lazy var firestore: Firestore = {
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        
        let firestore = Firestore.firestore()
        firestore.settings = settings
        return firestore
    }()
    var listener: ListenerRegistration!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.title = navigationTitle
        configDados(novoBrinquedo)

        prefixoTxt?.delegate = self
        telefoneTxt?.delegate = self
    }
    
    // MARK: - Method
    func configDados(_ novoBrinquedo: Bool) {
        
        if novoBrinquedo {
            
        } else {
            
            switch conservacao {
            case "Novo":
                conservacaoControl.selectedSegmentIndex = 0
            case "Usado":
                conservacaoControl.selectedSegmentIndex = 1
            case "Precisa de reparo":
                conservacaoControl.selectedSegmentIndex = 2
            default:
                conservacaoControl.selectedSegmentIndex = 1
            }
            
            self.nomeBrinquedoTxt?.text = brinquedo
            self.nomeDoadorTxt?.text = doador
            self.enderecoTxt?.text = endereco
            self.prefixoTxt?.text = "(\(telefone.prefix(2)))"
            self.telefoneTxt?.text = "\(telefone.dropFirst(2))"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength = 0
        
        if textField == self.prefixoTxt {
            maxLength = 2
        } else if textField == self.telefoneTxt {
            maxLength = 9
        }
        
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == self.prefixoTxt {
            textField.text = ""
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.prefixoTxt {
            
            if textField.text == "" || textField.text == "()" {
                textField.text = "(\(telefone.prefix(2)))"
            } else {
                if let prefixo = textField.text {
                    textField.text = "(\(prefixo))"
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func salvarButton(_ sender: UIButton) {
        
        guard let prefixo = prefixoTxt?.text?.dropFirst().dropLast() else { return }
        guard let numero = telefoneTxt?.text?.replacingOccurrences(of: "-", with: "") else { return }
        let telefoneConcatenado = "\(prefixo)\(numero)"
        
        guard let nomeBrinquedo = nomeBrinquedoTxt?.text,
                let nomeDoador = nomeDoadorTxt?.text,
                let endereco = enderecoTxt?.text,
                let conservacao = conservacaoControl.titleForSegment(at: conservacaoControl.selectedSegmentIndex) else { return }
        
        let data: [String: Any] = [
            "endereco": endereco,
            "estadoConservacao": conservacao,
            "nomeBrinquedo": nomeBrinquedo,
            "nomeDoador": nomeDoador,
            "telefone": telefoneConcatenado
        ]
        
        if !novoBrinquedo {
            self.firestore.collection(self.collection).document(id).updateData(data) { err in
                if let err = err {
                    print("Erro ao atualizar o brinquedo: \(err)")
                } else {
                    let alert = UIAlertController(title: "Atenção", message: "Brinquedo atualizado com sucesso!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { UIAlertAction in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            self.firestore.collection(self.collection).addDocument(data: data) { err in
                if let err = err {
                    print("Erro ao adicionar o brinquedo: \(err)")
                } else {
                    let alert = UIAlertController(title: "Atenção", message: "Brinquedo adicionado com sucesso!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { UIAlertAction in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

