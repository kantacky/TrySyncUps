import ComposableArchitecture
import XCTest

@testable import TrySyncUps

final class SyncUpsListTests: XCTestCase {
  @MainActor
  func testBasics() async {
    let store = TestStore(initialState: SyncUpsListFeature.State(syncUps: [.mock, .productMock])) {
      SyncUpsListFeature()
    }
    await store.send(.onDelete([1])) {
      $0.syncUps.remove(at: 1)
    }
  }

  @MainActor
  func testAddSyncUp() async {
    let store = TestStore(initialState: SyncUpsListFeature.State()) {
      SyncUpsListFeature()
    } withDependencies: {
      $0.uuid = .incrementing
    }
    await store.send(.addSyncUpButtonTapped) {
      $0.destination = .addSyncUp(SyncUpFormFeature.State(syncUp: SyncUp(id: UUID(0))))
    }
//    await store.send(.addSyncUp(.presented(.set(\.syncUp, SyncUp(id: UUID(0), title: "Morning Sync")))))
    await store.send(\.destination.addSyncUp.binding.syncUp, SyncUp(id: UUID(0), title: "Morning Sync")) {
      $0.destination?.addSyncUp?.syncUp.title = "Morning Sync"
    }
    await store.send(.addButtonTapped) {
      $0.destination = nil
      $0.syncUps = [
        SyncUp(id: UUID(0), title: "Morning Sync")
      ]
    }
  }

  @MainActor
  func testDeletion() async {
    let syncUp = SyncUp.mock
    let store = TestStore(initialState: SyncUpsListFeature.State(syncUps: [syncUp])) {
      SyncUpsListFeature()
    }

    await store.send(.syncUpTapped(id: syncUp.id)) {
      $0.destination = .syncUpDetail(SyncUpDetailFeature.State(syncUp: Shared(syncUp)))
    }
    await store.send(\.destination.syncUpDetail.deleteButtonTapped) {
      $0.destination?.syncUpDetail?.alert = AlertState {
        TextState("Are you sure you want to delete this sync up?")
      } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
          TextState("Delete")
        }
      }
    }
    await store.send(\.destination.syncUpDetail.alert.confirmDeletion) {
      $0.destination?.syncUpDetail?.alert = nil
    }
    await store.receive(\.destination.dismiss) {
      $0.destination = nil
      $0.syncUps = []
    }
  }

  @MainActor
  func testDeletion_NonExhaustive() async {
    let syncUp = SyncUp.mock
    let store = TestStore(initialState: SyncUpsListFeature.State(syncUps: [syncUp])) {
      SyncUpsListFeature()
    }
    store.exhaustivity = .off

    await store.send(.syncUpTapped(id: syncUp.id))
    await store.send(\.destination.syncUpDetail.deleteButtonTapped)
    await store.send(\.destination.syncUpDetail.alert.confirmDeletion)
    await store.receive(\.destination.dismiss) {
      $0.syncUps = []
    }
  }

  @MainActor
  func testModel() {
    let model = SyncUpsListModel(syncUps: [.mock, .productMock])
    model.onDelete([1])
//    XCTAssertEqual(model.syncUps, [.mock])
  }
}
