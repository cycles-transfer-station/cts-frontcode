import 'dart:indexed_db';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:js/js.dart';
import 'package:js/js_util.dart';



class IndexDB {
    
    static bool is_support_here() => window.indexedDB != null;
    
    static void delete_database(String db_name) {
        callMethod(window.indexedDB!, 'deleteDatabase', [db_name]);
    }
    
    
    final String name;
    Object idb_open_db_quest; // save the q bc it needs to stay 
    Object/*IDBDatabase*/ idb_database;
    
    
    
    IndexDB({required this.name, required this.idb_database, required this.idb_open_db_quest});
    
    static Future<IndexDB> open(String db_name, List<String> object_stores_names) async {
        var/*IDBOpenDBRequest*/ q = callMethod(window.indexedDB!, 'open', [db_name, 1]);
        late Object/*IDBDatabase*/ idb_database;
        
        setProperty(q, 
            'onupgradeneeded',
            allowInterop((event) {
                window.console.log('upgradeneeded');
                idb_database = getProperty(getProperty(event, 'target'), 'result');
                callMethod(idb_database, 'addEventListener', [
                    'error',
                    allowInterop((Event event) {
                        window.console.log(event);
                        window.alert('idb error');  
                    })  
                ]);
                for (String object_store_name in object_stores_names) {
                    Object/*IDBObjectStore.)*/ idb_object_store = callMethod(idb_database, 'createObjectStore', [ object_store_name ]);
                }
            })
        );
        
        bool onsuccessorerror = false;
        setProperty(q, 
            'onsuccess',
            allowInterop((event) {
                idb_database = getProperty(q, 'result');
                onsuccessorerror = true;
                
            })
        );
        setProperty(q, 
            'onerror',
            allowInterop((event) {
                onsuccessorerror = true;
            })
        );
        
        // poll the result
        while (onsuccessorerror == false || getProperty(q, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }        
        if (getProperty(q, 'readyState') != 'done') { throw Exception('unknown idb open request readyState'); }
        
        if (getProperty(q, 'error') == null) {
            return IndexDB(
                name: db_name, 
                idb_database: idb_database, 
                idb_open_db_quest: q,
            );
        } else {
            throw getProperty(q, 'error');
            //throw Exception('idb open request error');
        }
    
    }    
    
    
    List<String> object_store_names() {
        return getProperty(this.idb_database, 'objectStoreNames');
    }
    
    
    
    Future<dynamic> get_object({required String object_store_name, required String key}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly'/*'readwrite'*/, 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        callMethod(transaction, 'addEventListener', [
            'complete',
            allowInterop((Event event) {

            })
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        Object? value;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        value = getProperty(object_store_cursor_with_value!, 'value');
                        onsuccess_cursor_complete_orerror = true;
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            return value;
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        
    }
    
    
    // returns true if the object-add is success and false if the key is already in the object_store. use put to update a key.
    Future<bool> add_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly', // here to check if the key is already in the object_store
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        
        late Object?/*can be null if 0 objects*//*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        bool is_key_in_the_object_store = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        is_key_in_the_object_store = true;
                        onsuccess_cursor_complete_orerror = true;
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');

        }

        
        Object/*IDBTransaction)*/ transaction2 = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store2 = callMethod(transaction2, 'objectStore', [object_store_name]);
        
        bool transaction_complete = false;
        callMethod(transaction2, 'addEventListener', [
            'complete',
            allowInterop((event) {
                transaction_complete = true;
            })
        ]);
        
        Object/*IDBRequest*/ idb_quest_object_store_add = callMethod(object_store2, 'add', [value, key]);

        while (getProperty(idb_quest_object_store_add, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_add, 'error') == null) {
            // the add in the queue now wait for the complete
            while (transaction_complete == false) { await Future.delayed(Duration(milliseconds: 300)); }
            return true;
        } else {
            throw getProperty(idb_quest_object_store_add, 'error');
        }
        
        
    }
    
    
    // returns true if the object-put/update is success and false if the key is not found in the object_store. use add to add a new key.
    Future<bool> put_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        bool is_key_in_the_object_store = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) async {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        // update
                        Object/*IDBRequest*/ idb_quest_update = callMethod(object_store_cursor_with_value!, 'update', [value]);
                        // await here is ok bc we call cursor.update before this await and we wont call cursor.continue after this
                        while (getProperty(idb_quest_update, 'readyState') == 'pending') { await Future.delayed(Duration(milliseconds: 300)); } 
                        if (getProperty(idb_quest_update, 'error') == null) {
                            is_key_in_the_object_store = true;
                            onsuccess_cursor_complete_orerror = true;
                        } else {
                            throw getProperty(idb_quest_update, 'error');
                        }
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return true;
            } else {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        
        
    }
    
    
    void shutdown() {
        callMethod(this.idb_database, 'close', []);
    }
    

}




@JS()
@anonymous
class IDBDatabaseTransactionOptions  {
    external String get durability;
    
    external factory IDBDatabaseTransactionOptions({
        String durability
    });
}

