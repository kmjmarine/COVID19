//
//  ViewController.swift
//  COVID19
//
//  Created by kmjmarine on 2021/12/29.
//

import UIKit

import Alamofire //swift(URLSession)기반의 HTTP 네트워킹 라이브러리 - 네트워킹 작업을 단순화 함(Json파싱 등) / 코드의 단순화, 가독성 높임
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var lblTotalCase: UILabel!
    @IBOutlet weak var lblNewCase: UILabel!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var lblStackView: UIStackView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicatorView.startAnimating() //서버에서 응답이 오기 전 로딩애니메이션 시작
        self.fetchCovidOverview(completionHandler: { [weak self] result in //순환참조 방지
            guard let self = self else { return } //일시적으로 스트롱 매서드로 변환
            self.indicatorView.stopAnimating() //서버에서 응답이 온 후 로딩애니메이션 정지(completionHandler로 구분)
            self.indicatorView.isHidden = true
            self.lblStackView.isHidden = false
            self.pieChartView.isHidden = false
            switch result {
            case let .success(result):
                self.configureStackView(koreaCovidOverView: result.korea)
                let covidOverViewList = self.makeCovidOverviewList(cityCovidOverView: result)
                self.configureChartView(covidOverviewList: covidOverViewList)
            case let .failure(result):
                debugPrint("error \(result)")
            }
        })
    }
    
    func makeCovidOverviewList(
        cityCovidOverView: CityCovidOverview
    ) -> [CovidOverview] {
        return [ //Json CovidOverView 응답은 객체로 반환되기에 배열로 변환
            cityCovidOverView.seoul,
            cityCovidOverView.busan,
            cityCovidOverView.daegu,
            cityCovidOverView.incheon,
            cityCovidOverView.gwangju,
            cityCovidOverView.daejeon,
            cityCovidOverView.ulsan,
            cityCovidOverView.sejong,
            cityCovidOverView.gyeonggi,
            cityCovidOverView.gangwon,
            cityCovidOverView.chungbuk,
            cityCovidOverView.chungnam,
            cityCovidOverView.jeonbuk,
            cityCovidOverView.jeonnam,
            cityCovidOverView.gyeongbuk,
            cityCovidOverView.gyeongnam,
            cityCovidOverView.jeju,
        ]
    }
    
    func configureChartView(covidOverviewList: [CovidOverview]) {
        self.pieChartView.delegate = self
        let entries = covidOverviewList.compactMap { [weak self] overview -> PieChartDataEntry? in
            guard let self = self else { return nil }
            return PieChartDataEntry(
                value: self.removeFormatString(string: overview.newCase),
                label: overview.countryName,
                data: overview
            )
        }
        let dataSet = PieChartDataSet(entries: entries, label: "코로나 발생 현황")
        dataSet.sliceSpace = 1
        dataSet.entryLabelColor = .black
        dataSet.entryLabelColor = .black
        dataSet.xValuePosition = .outsideSlice
        dataSet.valueLinePart1OffsetPercentage = 0.8
        dataSet.valueLinePart1Length = 0.2
        dataSet.valueLinePart2Length = 0.3
        dataSet.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.joyful() + ChartColorTemplates.liberty() + ChartColorTemplates.pastel() + ChartColorTemplates.material()
        self.pieChartView.data = PieChartData(dataSet: dataSet)
        self.pieChartView.spin(duration: 0.6, fromAngle: self.pieChartView.rotationAngle, toAngle: self.pieChartView.rotationAngle + 80)
    }
    
    func removeFormatString(string: String) -> Double {
        let formmater = NumberFormatter()
        formmater.numberStyle = .decimal
        return formmater.number(from: string)?.doubleValue ?? 0
    }
    
    func configureStackView(koreaCovidOverView: CovidOverview) {
        self.lblTotalCase.text = "\(koreaCovidOverView.totalCase)명"
        self.lblNewCase.text = "\(koreaCovidOverView.newCase)명"
    }

    func fetchCovidOverview(
        //클로져에 응답받은 데이터 전달 (escaping 클로져)
        completionHandler: @escaping (Result<CityCovidOverview, Error>) -> Void
    ) {
        let url = "https://api.corona-19.kr/korea/country/new/"
        //딕셔너리 선언
        let param = [
            "serviceKey": "tBfPTFEsqweS9OhluDoKmz6i7Nc5QjrkJ"
        ]
        
        //Alamofire로 API호출 (request 메서드)
        AF.request(url, method: .get, parameters: param)
        //응답받을 데이터 체이닝 (응답받을 데이터가 클로져에 전달됨)
            .responseData(completionHandler: { response in
                switch response.result {
                case let .success(data):
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(CityCovidOverview.self, from: data)
                        completionHandler(.success(result)) //fecthCovidOverView의 completionHandler 클로져 호출
                    } catch {
                        completionHandler(.failure(error))
                    }
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            })
    }
}

extension ViewController: ChartViewDelegate {
    //차트의 항목을 선택했을때 호충되는 매서드(엔트리 파라미터를 통해 선택된 항목에 저장된 데이터를 가져옴)
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        //CovidDetailViewContoller로 푸쉬
        guard let covidDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "CovidDetailViewController") as? CovidDetailViewController else { return } //스토리보드의 CovidDetailViewController를 인스턴스화
        guard let covidOverView = entry.data as? CovidOverview else { return } //CovidOverView 타입으로 다운캐스팅
        covidDetailViewController.covidOverview = covidOverView
        self.navigationController?.pushViewController(covidDetailViewController, animated: true) //covidDetailViewController 에 데이터 푸쉬
    }
}
