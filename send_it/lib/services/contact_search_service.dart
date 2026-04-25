import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSearchService {
  /// Search contacts by name and/or company
  ///
  /// [contacts] - List of contacts to search through
  /// [query] - Search query string
  /// [searchName] - Whether to search in contact names (default: true)
  /// [searchCompany] - Whether to search in company names (default: true)
  ///
  /// Returns filtered list of contacts that match the search criteria
  static List<Contact> searchContacts(
    List<Contact> contacts,
    String query, {
    bool searchName = true,
    bool searchCompany = true,
  }) {
    if (query.isEmpty) {
      return contacts;
    }

    final lowercaseQuery = query.toLowerCase().trim();

    return contacts.where((contact) {
      bool matches = false;

      // Search in contact name
      if (searchName) {
        matches = matches ||
            contact.displayName.toLowerCase().contains(lowercaseQuery) ||
            contact.name.first.toLowerCase().contains(lowercaseQuery) ||
            contact.name.last.toLowerCase().contains(lowercaseQuery);
      }

      // Search in company names
      if (searchCompany && !matches) {
        matches = contact.organizations.any((org) =>
            org.company.toLowerCase().contains(lowercaseQuery) ||
            org.title.toLowerCase().contains(lowercaseQuery) ||
            org.department.toLowerCase().contains(lowercaseQuery));
      }

      return matches;
    }).toList();
  }

  /// Get search result details for a contact
  ///
  /// Returns information about which fields matched the search query
  static ContactSearchResult getSearchResult(Contact contact, String query) {
    final lowercaseQuery = query.toLowerCase().trim();
    final result = ContactSearchResult(contact: contact);

    // Check name matches
    if (contact.displayName.toLowerCase().contains(lowercaseQuery)) {
      result.matchedFields.add(SearchField.displayName);
    }
    if (contact.name.first.toLowerCase().contains(lowercaseQuery)) {
      result.matchedFields.add(SearchField.firstName);
    }
    if (contact.name.last.toLowerCase().contains(lowercaseQuery)) {
      result.matchedFields.add(SearchField.lastName);
    }

    // Check organization matches
    for (final org in contact.organizations) {
      if (org.company.toLowerCase().contains(lowercaseQuery)) {
        result.matchedFields.add(SearchField.company);
        result.matchedCompanies.add(org.company);
      }
      if (org.title.toLowerCase().contains(lowercaseQuery)) {
        result.matchedFields.add(SearchField.title);
        result.matchedTitles.add(org.title);
      }
      if (org.department.toLowerCase().contains(lowercaseQuery)) {
        result.matchedFields.add(SearchField.department);
        result.matchedDepartments.add(org.department);
      }
    }

    return result;
  }
}

/// Represents the result of a contact search with details about matched fields
class ContactSearchResult {
  final Contact contact;
  final Set<SearchField> matchedFields = <SearchField>{};
  final Set<String> matchedCompanies = <String>{};
  final Set<String> matchedTitles = <String>{};
  final Set<String> matchedDepartments = <String>{};

  ContactSearchResult({required this.contact});

  /// Get a summary of what matched the search
  String get matchSummary {
    if (matchedFields.isEmpty) return '';

    final summaries = <String>[];

    if (matchedFields.contains(SearchField.displayName)) {
      summaries.add('Name');
    }
    if (matchedFields.contains(SearchField.company)) {
      summaries.add('Company');
    }
    if (matchedFields.contains(SearchField.title)) {
      summaries.add('Title');
    }
    if (matchedFields.contains(SearchField.department)) {
      summaries.add('Department');
    }

    return summaries.join(', ');
  }
}

/// Enum representing different searchable fields
enum SearchField {
  displayName,
  firstName,
  lastName,
  company,
  title,
  department,
}
