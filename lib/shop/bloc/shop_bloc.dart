import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/shop/shop.dart';
import 'package:stream_transform/stream_transform.dart';

part 'shop_event.dart';
part 'shop_state.dart';

extension ShopStateExtension on ShopState {
  ShopLoaded? get asLoaded => this is ShopLoaded ? this as ShopLoaded : null;
}

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc(this._service, this.upload) : super(const ShopInitial()) {
    on<ShopGetItemsEvent>(
      _onGetItems,
      transformer: (events, mapper) {
        final searchEvents = events.where((e) => e.isSearch).debounce(throttleDuration);
        final scrollEvents = events.where((e) => !e.isSearch).throttle(throttleDuration);
        return droppable<ShopGetItemsEvent>().call(
          searchEvents.merge(scrollEvents),
          mapper,
        );
      },
    );
    on<ShopCreateItemEvent>(_onCreateItem);
    on<ShopDeleteItemEvent>(_onDeleteItem);
    on<ShopEditItemEvent>(_onEditItem);
  }
  static const throttleDuration = Duration(milliseconds: 300);

  final ShopService _service;
  final UploadBloc upload;

  Future<void> _onCreateItem(ShopCreateItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.createShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Created ${response.data?.name}');

      final updatedItems = [response.data!, ...?state.asLoaded?.items];

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded!.pagination,
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to create item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onEditItem(ShopEditItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.updateShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Updated: ${response.data?.name}');

      final currentItems = state.asLoaded?.items ?? <ShopItemModel>[];
      final updatedItems = currentItems.map((item) {
        return item.id == event.body.id ? response.data! : item;
      }).toList();

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded!.pagination,
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to update item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onDeleteItem(ShopDeleteItemEvent event, Emitter<ShopState> emit) async {
    LoadingOverlay.show();
    try {
      final response = await _service.deleteShopItem(event.body);
      if (!response.success) return;

      showSuccessSnackBar(null, 'Deleted ${event.body.name}');

      final updatedItems = List<ShopItemModel>.from(state.asLoaded?.items ?? [])
        ..removeWhere((item) => item.id == event.body.id);

      emit(
        ShopLoaded(
          paginatedItems: PaginatedResponse<ShopItemModel>(
            items: updatedItems,
            pagination: state.asLoaded?.pagination != null
                ? Pagination(
                    total: updatedItems.length,
                    page: state.asLoaded!.pagination.page,
                    limit: state.asLoaded!.pagination.limit,
                    totalPage: (updatedItems.length / state.asLoaded!.pagination.limit).ceil(),
                  )
                : Pagination(
                    total: updatedItems.length,
                    totalPage: 1,
                  ),
          ),
          searchQuery: state.asLoaded?.searchQuery ?? '',
          categoryFilter: state.asLoaded?.categoryFilter,
        ),
      );
    } catch (e) {
      showErrorSnackBar(null, 'Failed to delete item: $e');
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _onGetItems(ShopGetItemsEvent event, Emitter<ShopState> emit) async {
    final currentState = state.asLoaded;

    final newSearchQuery = event.searchQuery ?? currentState?.searchQuery ?? '';
    final newCategoryFilter = event.categoryFilter;
    final newPage = event.page ?? (currentState?.pagination.page ?? 1);
    final newPageSize = event.limit ?? (currentState?.pagination.limit ?? 10);

    final isFilterChange =
        newSearchQuery != currentState?.searchQuery || newCategoryFilter != currentState?.categoryFilter;

    final effectivePage = isFilterChange ? 1 : newPage;

    final showFilterLoading = effectivePage == 1 && isFilterChange;

    if (state is ShopInitial || (event.forceRefresh && effectivePage == 1) || showFilterLoading) {
      emit(const ShopLoading());
    }

    try {
      final response = await _service.getShopItems(
        page: effectivePage,
        limit: newPageSize,
        searchQuery: newSearchQuery,
        categoryFilter: newCategoryFilter?.id.toString() ?? '',
      );

      if (response.success && response.data != null) {
        final paginatedItems = response.data!.items;
        final pagination = response.data!.pagination;

        var allItems = <ShopItemModel>[];

        if (event.forceRefresh || isFilterChange || effectivePage == 1) {
          allItems = paginatedItems;
        } else {
          allItems = [...currentState!.items, ...paginatedItems];
        }

        emit(
          ShopLoaded(
            paginatedItems: PaginatedResponse(
              items: allItems,
              pagination: pagination,
            ),
            searchQuery: newSearchQuery,
            categoryFilter: newCategoryFilter,
          ),
        );
      }
    } catch (e) {
      emit(ShopError('Failed to load items: $e'));
    }
  }
}
