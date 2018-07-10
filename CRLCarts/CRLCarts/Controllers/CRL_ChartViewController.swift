
import UIKit
import Charts
import Alamofire

class CRL_ChartViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    var globalData: [String] = []
    var arrayMeteoData: [MeteoDataEntry] = []
    
    let url = "https://www.metoffice.gov.uk/pub/data/weather/uk/climate/stationdata/bradforddata.txt"
    let amountMonthInYear:Double = 12
    
   class MeteoDataEntry {
        var year:Int
        var month:Int
        var afDays:Int
        var sunDays:Double
        var tMax:Double
        var tMin:Double
        var mm:Double
        var isProvisional:Bool = false
        
        init(year: Int, month: Int, afDays:Int, sunDays:Double, tMax:Double, tMin:Double, mm:Double){
            self.year = year
            self.month = month
            self.tMax = tMax
            self.tMin = tMin
            self.afDays = afDays
            self.mm = mm
            self.sunDays = sunDays
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alomofireRequest()
    }

    func alomofireRequest() {
        
        let indexOfYear    = 0
        let indexOfMonth   = 1
        let indexOfAfDays  = 4
        let indexOfSunDays = 6
        let indexOfTMax    = 2
        let IndexOfTMin    = 3
        let indexOfMm      = 5
        let indexOfProvisinalData = 7
        let initialIndexOfTable   = 7
        
        var lineChartEntryMax = [ChartDataEntry]()
        var lineChartEntryMin = [ChartDataEntry]()
        
        Alamofire.request(url).response { response in
            DispatchQueue.global().async {
                guard response.error == nil else {
                    return
                }
                
                if let data = response.data {
                    
                    let convertedData = String(data: data, encoding: .utf8)
                    let readings = convertedData?.components(separatedBy: "\n") as! [String]
                    
                    for i in initialIndexOfTable..<readings.count {
                        let regex = try? NSRegularExpression(pattern: " +", options: .caseInsensitive)
                        
                        if regex != nil {
                            var modString = regex!.stringByReplacingMatches(in: readings[i], range: NSMakeRange(0, readings[i].count), withTemplate: "\t")
                            
// MARK: - Remove all rubbish from data
                            modString.remove(at: modString.startIndex)
                            modString = modString.replacingOccurrences(of: "\r", with: "", options: NSString.CompareOptions.literal, range: nil)
                            modString = modString.replacingOccurrences(of: "*", with: "", options: NSString.CompareOptions.literal, range: nil)
                            modString = modString.replacingOccurrences(of: "--", with: "00", options: NSString.CompareOptions.literal, range: nil)
                            modString = modString.replacingOccurrences(of: "00-", with: "0", options: NSString.CompareOptions.literal, range: nil)
                            
                            var meteoData = modString.components(separatedBy: "\t")
                            
                            let meteoDataEntryInstance = MeteoDataEntry.init(year:  Int(meteoData[indexOfYear])!, month: Int(meteoData[indexOfMonth])!, afDays: Int(meteoData[indexOfAfDays])!, sunDays: Double(meteoData[indexOfSunDays])!, tMax: Double( meteoData[indexOfTMax])!, tMin: Double(meteoData[IndexOfTMin])!, mm: Double( meteoData[indexOfMm])!)
                            
                            if meteoData.count > indexOfProvisinalData, meteoData[indexOfProvisinalData].contains("Provisional") {
                                meteoDataEntryInstance.isProvisional = true
                            }
                            
                            var tempVariable = " "
                            tempVariable = String(meteoDataEntryInstance.year) + " " +
                                String(meteoDataEntryInstance.month) + " " + String(meteoDataEntryInstance.tMax) + " " +
                                String(meteoDataEntryInstance.tMin) + " " +
                                String(meteoDataEntryInstance.afDays) + " " +
                                String(meteoDataEntryInstance.mm) + " " +
                                String(meteoDataEntryInstance.sunDays)
                       
                            self.globalData.append(tempVariable)
                            self.arrayMeteoData.append(meteoDataEntryInstance)
                            
                            lineChartEntryMax.append(ChartDataEntry(
                                x: Double(meteoDataEntryInstance.year) + Double(meteoDataEntryInstance.month)/self.amountMonthInYear,
                                y: Double(meteoDataEntryInstance.tMax)))
                            
                            lineChartEntryMin.append(ChartDataEntry(
                                x: Double(meteoDataEntryInstance.year) + Double(meteoDataEntryInstance.month)/self.amountMonthInYear,
                                y: Double(meteoDataEntryInstance.tMin)))
                        }
                    }
                }
// MARK: - Statictic drawing
                DispatchQueue.main.async {
                    
                    let lineForMax = LineChartDataSet(values: lineChartEntryMax, label: "MaxTemp")
                    let lineForMin = LineChartDataSet(values: lineChartEntryMin, label: "MinTamp")
                    lineForMax.circleColors = [NSUIColor.blue]
                    lineForMin.circleRadius = 0.1
                    lineForMax.circleRadius = 0.1
                    lineForMin.circleColors = [NSUIColor.black]
                    lineForMax.colors = [NSUIColor.blue]
                    lineForMin.colors = [NSUIColor.black]
                    
                    let data = LineChartData()
                    data.addDataSet(lineForMax)
                    data.addDataSet(lineForMin)
                    
                    self.lineChartView.data = data
                    self.lineChartView.scaleYEnabled = false
                    self.lineChartView.zoom(scaleX: 8, scaleY: 1, x: 2018, y: -30)
                    
                    var x :[[MeteoDataEntry]] = [[]]
                    x.append([self.arrayMeteoData[1]])
                    x.append([self.arrayMeteoData[2]])
                }
            }
        }
    }
}

extension CRL_ChartViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return globalData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "MeteoCell") as! MeteoCell

        cell.textLabel?.text = globalData[indexPath.row]
        return cell
    }
}




