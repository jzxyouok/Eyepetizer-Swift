//
//  RxTableViewSectionedAnimatedDataSource.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 6/27/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import UIKit
#if !RX_NO_MODULE
import RxSwift
import RxCocoa
#endif

open class RxTableViewSectionedAnimatedDataSource<S: AnimatableSectionModelType>
    : TableViewSectionedDataSource<S>
    , RxTableViewDataSourceType {
    
    public typealias Element = [S]
    public var animationConfiguration = AnimationConfiguration()

    var dataSet = false

    public override init() {
        super.init()
    }

    open func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        UIBindingObserver(UIElement: self) { dataSource, newSections in
            #if DEBUG
                self._dataSourceBound = true
            #endif
            if !self.dataSet {
                self.dataSet = true
                dataSource.setSections(newSections)
                tableView.reloadData()
            }
            else {
                DispatchQueue.main.async {
                    // if view is not in view hierarchy, performing batch updates will crash the app
                    if tableView.window == nil {
                        tableView.reloadData()
                        return
                    }
                    let oldSections = dataSource.sectionModels
                    do {
                        let differences = try differencesForSectionedView(initialSections: oldSections, finalSections: newSections)

                        for difference in differences {
                            dataSource.setSections(difference.finalSections)

                            tableView.performBatchUpdates(difference, animationConfiguration: self.animationConfiguration)
                        }
                    }
                    catch let e {
                        rxDebugFatalError(e)
                        self.setSections(newSections)
                        tableView.reloadData()
                    }
                }
            }
        }.on(observedEvent)
    }
}
