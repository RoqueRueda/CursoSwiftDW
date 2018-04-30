//
//  ViewController.swift
//  swiftBountyHunter
//
//  Created by DW on 07/11/16.
//  Copyright © 2016 DW. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    let textCellIdentifier = "TextCell"
    let Nombres = ["Carlos Martinez", "Armando Olmos", "Guillermo Ortega", "Ivan Dammy", "David Martinez"]
    
    //Matriz de fugitivos
    var swiftFugitivos: Array<Array<String>> = []
    //Variable de base de datos
    var dbFugitivos: DBProvider?
    //Variable estática de control de pestañas y carga de información
    static var indexchange = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Se crea la base de datos
        if self.dbFugitivos == nil
        {
            self.dbFugitivos = DBProvider(crear: true)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //Asignación del delegado para captura de eventos de cambio de pestaña
        self.tabBarController?.delegate = self as UITabBarControllerDelegate
        
        //Cerradura para encapsular el contexto de la vista y enviarlo al segundo plano
        let funcion = {
            (error:Int) in
            if error != 1
            {
                //Si no existe error se realizará la recarga del tableView en el hilo principal
                DispatchQueue.main.async {
                    self.cargarListadoFugitivos(estatus: String(self.tabBarController!.selectedIndex))
                    self.tableView.reloadData()
                }
            }
            else
            {
                //Si existe algún error se lanzara una alerta indicandonos que se presento un error al consumir el servicio
                DispatchQueue.main.async {
                    let alerta = UIAlertController(title: "Error", message: "Error al consumir el WebService verbo GET",    preferredStyle: UIAlertControllerStyle.alert)
                    alerta.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alerta, animated: true, completion: nil)
                }
            }
        }
        //Se evalua si existen fugitivos en la base de datos
        if (dbFugitivos?.contarFugitivos())! <= 0
        {
            let ws:NetServices = NetServices()
            ws.connectGET(completado: funcion)
        }

        
        //Carga del listado de fugitivos
        cargarListadoFugitivos(estatus: "0")
        tableView.reloadData()
        
        
    }
    
    
    
    func showMenu() {
        let alertController = UIAlertController(title: "Log de Eliminacion", message: "Selecciona un elemento", preferredStyle: .actionSheet)
        
        let navigateToDeleteLog = UIAlertAction(title: "Eliminados", style: .default, handler: {
            (action) -> Void in
            print("Eliminados")
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action) -> Void in
            print("Cancel")
        })
        
        alertController.addAction(navigateToDeleteLog)
        alertController.addAction(cancelButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        if ViewController.indexchange == 1
        {
            DispatchQueue.main.async {
                //Una vez que apareció la vista cambiamos nuestra variable para indicar que ya fueron actualizadas las listas despues de una inserción
                self.tabBarController?.selectedIndex = 0
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Evento para cerrar la ventana modal cuando se le de click al botón "cancel" desde "Agregar" o "Detalle"
    @IBAction func Cancel(_ unwindSegue: UIStoryboardSegue)
    {
        //Imprime el nombre desde el cual se mando llamar
        print(unwindSegue.identifier!)
    }
    
    @IBAction func showMenuOptions(_ unwindSegue: UIStoryboardSegue)
    {
        showMenu()
    }
    
    //UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return swiftFugitivos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier)! as UITableViewCell
        
        let row = indexPath.row
        cell.textLabel?.text = swiftFugitivos[row][1]
        
        return cell
    }
    //UITableViewDataSource
    
    
    //UITableViewDelegate
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    //UITableViewDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "DetalleFugitivos" || segue.identifier == "DetalleCapturados")
        {
            let detalleController:DetalleViewController = segue.destination as! DetalleViewController
            detalleController.NombreFugitivo = swiftFugitivos[tableView.indexPathForSelectedRow!.row][1]
            detalleController.id = swiftFugitivos[tableView.indexPathForSelectedRow!.row][0]
            detalleController.Estatus = String(self.tabBarController!.selectedIndex)
        }
    }
    
    //Método para cargar los datos de los fugitivos de la base de datos
    func cargarListadoFugitivos(estatus:String)
    {
        swiftFugitivos.removeAll()
        swiftFugitivos = dbFugitivos!.obtenerFugitivos(pEstatus: estatus)
    }
    
    //Evento para cerrar la ventana de agregar/eliminar/capturar y actualizar las listas
    @IBAction func segueInsUpdDel(_ unwindSegue: UIStoryboardSegue)
    {
        //Imprime el identificador del Segue que disparó el evento
        print(unwindSegue.identifier!)
        
        //Se evalua si retorna de la ViewController de agregar
        if unwindSegue.identifier == "Agregar"
        {
            //Cambia la propiedad estática indexchange para indicar que se deberán actualizar las listas y se manda llamar al método del ciclo de vida de la view controller llamado viewDidAppear()
            ViewController.indexchange = 1
            viewDidAppear(false)
        }
        else
        {
            //Se ejecuta la carga de fugitivos y la actualización de las listas cuando se viene de la ViewController de detalle
            cargarListadoFugitivos(estatus: String(self.tabBarController!.selectedIndex))
            print("myUnwindAction: \(String(self.tabBarController!.selectedIndex))")
            self.tableView.reloadData()
        }
    }
    
    //UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        //Se cambia la variable estática a 0 para indicar que la carga de la lista de fugitivos se llevó a cabo
        ViewController.indexchange = 0
        //Se carga la lista de fugitivos y se actualiza la tabla
        cargarListadoFugitivos(estatus: String(self.tabBarController!.selectedIndex))
        self.tableView.reloadData()
        //Se evalúa si se encuentra en la lista de fugitivos para mandar llamar al método del ciclo de vida viewWillAppear() para actualizar la lista de fugitivos cuando se haya agregado desde la pestaña de capturados
        if self.tabBarController?.selectedIndex == 0
        {
            viewWillAppear(false)
        }
    }
    //UITabBarControllerDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        //Se obtiene una instancia del hilo de UI para realizar la actualización de las listas
        DispatchQueue.main.async {
            //Recarga de datos al regresar de agregar de la pestaña de fugitivos o capturados y acerca de
            self.cargarListadoFugitivos(estatus: String(self.tabBarController!.selectedIndex))
            self.tableView.reloadData()
        }
    }
    
}

