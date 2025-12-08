import UIKit
class BookingViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var timeCollectionView: UICollectionView!
    let times = ["9:00 AM", "12:00 PM", "4:00 PM", "5:30 PM"]
    var selectedTimeIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        timeCollectionView.dataSource = self
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return times.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeCell", for: indexPath) as! TimeCell
        cell.timeLabel.text = times[indexPath.row]
        
        if indexPath.row == selectedTimeIndex {
            cell.contentView.backgroundColor = .blue
            cell.timeLabel.textColor = .white
        } else {
            cell.contentView.backgroundColor = UIColor.systemGray6
            cell.timeLabel.textColor = .black
        }
        cell.contentView.layer.cornerRadius = 10
        return cell
    }
}
