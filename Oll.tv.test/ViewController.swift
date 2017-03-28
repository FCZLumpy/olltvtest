import UIKit

enum directionList: Int {
    case toUp = -1
    case toDown = 1
}

struct TVProgramm {
    let url: String
    let name: String
    let id: Int
}

class TableViewCell: UITableViewCell {
    @IBOutlet weak var tfProgrammName: UILabel!
    @IBOutlet weak var programmImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    var tvProgrammArray: [TVProgramm] = []
    var itemsNumber = 0
    let uuid = UUID().uuidString
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
    var indexPaths: [IndexPath] = []
    var lastElement = 0
   
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        spinner.center = view.center
        spinner.hidesWhenStopped = true
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        view.addSubview(spinner)
        spinner.startAnimating()
        
        //first request
        Networking.sharedInstance.setParams(serialNumber: uuid)
        Networking.sharedInstance.sendToServerGet( callback: { [unowned self] (result, error)   in
            if(error == 0) {
                if let data = result["items"] {
                    self.tvProgrammArray = []
                    for tvProgramm in data as! Array<Dictionary<String, AnyObject>> {
                        let TVProgrammModel = TVProgramm(url: tvProgramm["icon"] as! String, name: tvProgramm["name"] as! String, id: tvProgramm["id"] as! Int)
                        self.tvProgrammArray.append(TVProgrammModel)
                    }
                }
                if let items = result["items_number"] {
                    self.itemsNumber = items as! Int
                    self.lastElement = self.itemsNumber - 1
                }
                self.spinner.stopAnimating()
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tvProgrammArray.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        cell.tfProgrammName.text = tvProgrammArray[indexPath.row].name
        let url = URL(string: tvProgrammArray[indexPath.row].url)
        
        if(cell.spinner != nil) {
            cell.spinner.startAnimating()
        }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url!) {
                DispatchQueue.main.async {
                    cell.programmImage.image = UIImage(data: data)
                    if(cell.spinner != nil) {
                        cell.spinner.stopAnimating()
                        cell.spinner.removeFromSuperview()
                    }
                }
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //load if scroll to bottom
        if indexPath.row == lastElement {
            sendRequest(borderId: tvProgrammArray[itemsNumber - 1].id, direction: directionList.toDown.rawValue)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //load if scroll to top
        if scrollView.contentOffset.y == 0 {
            sendRequest(borderId: tvProgrammArray[0].id, direction: directionList.toUp.rawValue)
        }
    }
    
    func sendRequest(borderId: Int, direction: Int)  {
        spinner.startAnimating()
        Networking.sharedInstance.setParams(serialNumber: uuid, borderId: borderId, direction: direction)
        Networking.sharedInstance.sendToServerGet( callback: { [unowned self] (result, error)   in
            if(error == 0) {
                
                //check if list ends
                let hasMore = result["hasMore"] as! Int
                let offset = result["offset"] as! Int
                let itemsNumber = result["items_number"] as! Int
                if(direction == directionList.toUp.rawValue && offset < itemsNumber ) {
                    return
                }
                
                if(direction == directionList.toDown.rawValue && hasMore < itemsNumber ) {
                    return
                }
               
                self.tableView.beginUpdates()
                if let data = result["items"] {
                    var i = 0
                    for tvProgramm in data as! Array<Dictionary<String, AnyObject>> {
                        let TVProgrammModel = TVProgramm(url: tvProgramm["icon"] as! String, name: tvProgramm["name"] as! String, id: tvProgramm["id"] as! Int)
                        if(direction == directionList.toUp.rawValue) {
                            self.tvProgrammArray.insert(TVProgrammModel, at: 0)
                            self.indexPaths.insert(IndexPath(item: i, section: 0), at: 0)
                        } else {
                            self.tvProgrammArray.append(TVProgrammModel)
                            self.indexPaths.append(IndexPath(item: i, section: 0))
                        }
                       
                        i += 1
                    }
                    i = 0
                }
                self.tableView.insertRows(at: self.indexPaths, with: .automatic)
                self.tableView.endUpdates()
                self.spinner.stopAnimating()
                
            }
        })
        lastElement += itemsNumber

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

