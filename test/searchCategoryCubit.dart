import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';

enum SearchCategory { All, Active, Completed }

class SearchCategoryCubit extends Cubit<SearchCategory> with CubitEx {
  SearchCategoryCubit() : super(SearchCategory.All) {
    $initEx();
  }

  void setCategory(SearchCategory category) => emit(category);
}
