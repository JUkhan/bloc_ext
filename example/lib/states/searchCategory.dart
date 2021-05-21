import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';

enum SearchCategory { All, Active, Completed }

class SearchCategoryState extends Cubit<SearchCategory> with CubitEx {
  SearchCategoryState() : super(SearchCategory.All) {
    $initEx();
  }

  void setCategory(SearchCategory category) => emit(category);
}
