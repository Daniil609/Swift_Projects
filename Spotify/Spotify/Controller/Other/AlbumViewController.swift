
import UIKit

class AlbumViewController: UIViewController {

    private let album:Album
    
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout(
            sectionProvider: {_,_ -> NSCollectionLayoutSection? in

        let item = NSCollectionLayoutItem(
            layoutSize:  NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2)

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(60)
            ),
            subitem: item,
            count: 1
        )

        let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [
                    NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .fractionalWidth(1)
                        ),
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top
                    )
                ]
        return section
    })
    )
    
    private var viewModels = [AlbumCollectionViewModel]()
    private var tracks = [AudioTrack]()
    init(album:Album){
        self.album = album
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = album.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            AlbumTrackCollectionViewCell.self,
            forCellWithReuseIdentifier: AlbumTrackCollectionViewCell.identifier
        )
        collectionView.register(
            PlaylistHeaderUICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PlaylistHeaderUICollectionReusableView.identifier
        )
        fethData()
       
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didTapAction))
    }
    
    @objc func didTapAction(){
        let actionSheet = UIAlertController(title: album.name, message: "Actions", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Save Album", style: .default, handler: {_ in
            APICaller.shared.saevAlbum(album: self.album) { success in
                NotificationCenter.default.post(name: .albumSaveNotification, object: nil)
            }
        }))
        present(actionSheet, animated: true)
    }
    
    private func fethData(){
        APICaller.shared.getAlbimDetailes(for: album) {[weak self] result in
            DispatchQueue.main.async {
                switch result{
                case.success(let model):
                    self?.tracks = model.tracks.items
                    self?.viewModels = model.tracks.items.compactMap({
                        AlbumCollectionViewModel(
                            name: $0.name,
                            artistName: $0.artists.first?.name ?? "-"
                            )

                    })
                    self?.collectionView.reloadData()
                    break
                case.failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    

}
extension AlbumViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumTrackCollectionViewCell.identifier, for: indexPath) as? AlbumTrackCollectionViewCell else{
            return UICollectionViewCell()
        }
        cell.configre(with: viewModels[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PlaylistHeaderUICollectionReusableView.identifier,
            for: indexPath
        ) as? PlaylistHeaderUICollectionReusableView, kind == UICollectionView.elementKindSectionHeader  else{
            return UICollectionReusableView()
        }
        let headerViewModel = PlaylistHeaderViewModel(
            playlistName: album.name,
            owner: album.artists.first?.name,
            description: "Release Date:\(String.formatterData(string: album.release_date))",
            artWorkURL: URL(string: album.images.first?.url ?? "")
        )
        header.configure(with:headerViewModel)
        header.delegete = self
        return header

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        var track = tracks[indexPath.row]
        track.album = self.album
        PlaybackPresenter.shared.startPlayback(from: self, track: track)
    }

}
extension AlbumViewController: PlaylistHeaderUICollectionReusableViewDelegete{
    func PlaylistHeaderUICollectionReusableViewDidTapAll(_ header: PlaylistHeaderUICollectionReusableView) {
        let trackWithAlbum:[AudioTrack] = tracks.compactMap {
            var track = $0
            track.album = self.album
            print(track.album)
            return track
            
        }
        PlaybackPresenter.shared.startPlayback(from: self, tracks: trackWithAlbum)
    }
    
    
}

