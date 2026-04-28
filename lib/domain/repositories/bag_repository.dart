import '../entities/bag.dart';

abstract class BagRepository {
  Future<List<Bag>> getBagsByTrip(String tripId);
  Future<Bag> createBag(Bag bag);
  Future<Bag> updateBag(Bag bag);
  Future<void> deleteBag(String id);
}
