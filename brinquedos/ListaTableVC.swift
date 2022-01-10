//
//  ListaTableVC.swift
//  brinquedos
//
//  Created by Lucas Barcelos on 09/01/22.
//

import UIKit
import FirebaseFirestore

class ListaTableVC: UITableViewController {
    
    // MARK: - Properties
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
    var indexRow: Int?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadBrinquedoLista()
    }
    
    // MARK: - Methods
    func loadBrinquedoLista() {
        listener = firestore.collection(collection).order(by: "nomeBrinquedo", descending: false).addSnapshotListener(includeMetadataChanges: true, listener: { snapshot, error in
            if let error = error {
                print(error)
            } else {
                guard let snapshot = snapshot else { return }
                print("Total de docs alterados: \(snapshot.documentChanges.count)")
                if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                    self.showItemsFrom(snapshot)
                }
            }
        })
    }
    
    func showItemsFrom(_ snapshot: QuerySnapshot) {
        brinquedoLista.removeAll()
        
        for document in snapshot.documents {
            let data = document.data()
            if let nomeBrinquedo = data["nomeBrinquedo"] as? String,
                let nomeDoador = data["nomeDoador"] as? String,
                let endereco = data["endereco"] as? String,
                let telefone = data["telefone"] as? String,
               let estadoConservacao = data["estadoConservacao"] as? String {
                
                let brinquedoLista = BrinquedoItem(nomeBrinquedo: nomeBrinquedo,
                                                   estadoConservacao: estadoConservacao,
                                                   nomeDoador: nomeDoador,
                                                   endereco: endereco,
                                                   telefone: telefone,
                                                   id: document.documentID)
                self.brinquedoLista.append(brinquedoLista)
            }
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return brinquedoLista.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let brinquedoItem = brinquedoLista[indexPath.row]
        
        cell.textLabel?.text = brinquedoItem.nomeBrinquedo
        cell.detailTextLabel?.text = brinquedoItem.estadoConservacao

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.indexRow = indexPath.row
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let brinquedoItem = brinquedoLista[indexPath.row]
            firestore.collection(collection).document(brinquedoItem.id).delete() { error in
                if let error = error {
                    let alert = UIAlertController(title: "Atenção", message: "\(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Atenção", message: "Brinquedo excluído da lista com sucesso!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { UIAlertAction in
                        self.tableView.reloadData()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        if segue.identifier == "cadastro" {
            if let vc = segue.destination as? CadastroAlteracaoVC {
                vc.navigationTitle = "Cadastro"
                vc.novoBrinquedo = true
            }
        } else if segue.identifier == "edicao" {
            if let vc = segue.destination as? CadastroAlteracaoVC {
                vc.navigationTitle = "Edição"
                let brinquedo = brinquedoLista[indexRow ?? 0]
                vc.novoBrinquedo = false
                vc.brinquedo = brinquedo.nomeBrinquedo
                vc.doador = brinquedo.nomeDoador
                vc.endereco = brinquedo.endereco
                vc.conservacao = brinquedo.estadoConservacao
                vc.telefone = brinquedo.telefone
                vc.id = brinquedo.id
            }
        }
        backItem.title = "Voltar"
        navigationItem.backBarButtonItem = backItem
    }
}
