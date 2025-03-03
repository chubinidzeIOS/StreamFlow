//
//  HomeController.swift
//  StreamFlow
//
//  Created by ilomidze on 08.05.21.
//

import UIKit

class HomeController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Properties
    
    // MARK: General Properties
    
    var movieOfTheDayDataIsDownloaded = false
    var newAddedMoviesDataIsDownloaded = false
    var popularMoviesDataIsDownloaded = false
    var popularSeriesDataIsDownloaded = false

    
    // MARK: Data for each Section
    
    var movieOfTheDayData = MovieData() {
        didSet {
            downloadSectionMovieImages(on: .movieOfTheDay)
        }
    }
    ///
    var newAddedMoviesData = [MovieData]() {
        didSet {
            downloadSectionMovieImages(on: .newAdded)
        }
    }
    ///
    var popularMoviesData = [MovieData]() {
        didSet {
            downloadSectionMovieImages(on: .popularMovies)
        }
    }
    ///
    var popularSeriesData = [MovieData]() {
        didSet {
            downloadSectionMovieImages(on: .popularSeries)
        }
    }

    
    // MARK: - Execution
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "HomeController"
        navigationController?.navigationBar.barTintColor = UIColor.init(red: CGFloat(10/255), green: CGFloat(5/255), blue: CGFloat(10/255), alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        tableView.register(UINib(nibName: "TitleCell", bundle: nil), forCellReuseIdentifier: "TitleCell")
        tableView.register(UINib(nibName: "SectionCell", bundle: nil), forCellReuseIdentifier: "SectionCell")
        
        getMovieOfTheDayData()
        getNewAddedMoviesData()
        getPopularMoviesData()
        getPopularSeriesData()
    }
    
    
    // MARK: - Functions
    
    //MARK: Fetching Data
    
    /// Gets Movie of the day Data from iMovies API
    func getMovieOfTheDayData() {
        DataRequestManager.instance.getData(requestType: HomeNetworkRequest.movieOfTheDay) { [weak self] (result: Result<MovieDataArr, ErrorRequests>)  in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let movieDataArr):
                self?.movieOfTheDayData = (movieDataArr.data?[0]) ?? MovieData()
            }
        }
    }
    
    /// Gets New added movies Data from iMovies API
    func getNewAddedMoviesData() {
        DataRequestManager.instance.getData(requestType: HomeNetworkRequest.newAddedMovies) { [weak self] (result: Result<MovieDataArr, ErrorRequests>) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let movieDataArr):
                self?.newAddedMoviesData = movieDataArr.data ?? [MovieData()]
            }
        }
    }
    
    /// Gets Popular  movies Data from iMovies API
    func getPopularMoviesData() {
        DataRequestManager.instance.getData(requestType: HomeNetworkRequest.popularMovies) { [weak self] (result: Result<MovieDataArr, ErrorRequests>) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let movieDataArr):
                self?.popularMoviesData = movieDataArr.data ?? [MovieData()]
            }
        }
    }
    
    /// Gets Popular  series Data from iMovies API
    func getPopularSeriesData() {
        DataRequestManager.instance.getData(requestType: HomeNetworkRequest.popularSeries) { [weak self] (result: Result<MovieDataArr, ErrorRequests>) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let movieDataArr):
                self?.popularSeriesData = movieDataArr.data ?? [MovieData()]
            }
        }
    }
    
    // MARK: Fetching Images
    
    /// Downloads all the images for the corresponding section class and saves them in that class data
    func downloadSectionMovieImages(on sectionName: SectionNames) {
        // choose which section class should be changed
        var editableSectionClass: [MovieData]
        
        switch sectionName {
        case .movieOfTheDay:
            if movieOfTheDayDataIsDownloaded {
                return
            }
            movieOfTheDayDataIsDownloaded = true
            editableSectionClass = [movieOfTheDayData]
        case .newAdded:
            if newAddedMoviesDataIsDownloaded {
                return
            }
            newAddedMoviesDataIsDownloaded = true
            editableSectionClass = newAddedMoviesData
        case .popularMovies:
            if popularMoviesDataIsDownloaded {
                return
            }
            popularMoviesDataIsDownloaded = true
            editableSectionClass = popularMoviesData
        case .popularSeries:
            if popularSeriesDataIsDownloaded {
                return
            }
            popularSeriesDataIsDownloaded = true
            editableSectionClass = popularSeriesData
        }
        
        if sectionName != .movieOfTheDay {
            //To add number of cells according to the fetched data
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
        
        //Download image for each cell
        for itemIndex in 0..<(editableSectionClass.count) {
            if sectionName == .movieOfTheDay {
                guard let maxSizeImageURL = editableSectionClass[itemIndex].covers?.data?.maxSize else {
                    print("\(sectionName): No cover url in \(itemIndex)th element")
                    return
                }
                downloadImageAndUpdateCell(for: editableSectionClass[itemIndex], from: maxSizeImageURL, sectionName: sectionName, itemInSection: itemIndex)
            } else {
                guard let minSizeImageURL = editableSectionClass[itemIndex].covers?.data?.minSize else {
                    print("\(sectionName): No cover url in \(itemIndex)th element")
                    return
                }
                downloadImageAndUpdateCell(for: editableSectionClass[itemIndex], from: minSizeImageURL, sectionName: sectionName, itemInSection: itemIndex)
            }
        }
    }
    
    
    /// Downloads image from url, Saves int to specified MovieData class data and Updates appropriate  [titleCell or collectionView cell]
    func downloadImageAndUpdateCell(for movieData: MovieData, from urlString: String, sectionName: SectionNames, itemInSection: Int) {
        DataRequestManager.instance.getImage(urlString: urlString) { [weak self] resultData in
            switch resultData {
            case .failure(let error):
                print("Error: Cover image download for \(String(describing: movieData.originalName ?? "No Movie Name"))  - \(error)")
                movieData.imageData = UIImage(named: "NoMovieCover")!.pngData()
            case .success(let data):
                movieData.imageData = data
                
                DispatchQueue.main.async {
                    if sectionName == .movieOfTheDay {
                        let titleCell = self?.tableView.cellForRow(at: IndexPath(row: sectionName.rawValue, section: 0)) as! TitleCell
                        
                        titleCell.updateImage()
                        self?.tableView.reloadRows(at: [IndexPath(row: sectionName.rawValue, section: 0)], with: .automatic)
                        
                    } else {
                        let sectionCell = self?.tableView.cellForRow(at: IndexPath(row: sectionName.rawValue, section: 0)) as! SectionCell
                        
                        if let movieListCollectionCell = sectionCell.collectionView.cellForItem(at: IndexPath(item: itemInSection, section: 0)) as? MovieListCollectionCell {
                            
                            movieListCollectionCell.updateImage()
                            sectionCell.collectionView.reloadItems(at: [IndexPath(item: itemInSection, section: 0)])
                        }
                    }
                }
            }
        }
    }
    
    // ec
}


