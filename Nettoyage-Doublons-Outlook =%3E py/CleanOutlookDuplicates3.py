if __name__ == "__main__":
    if not com_init():
        sys.exit(3)
    
    try:
        # Code principal ici (doit être indenté)
        result = clean_old_emails()
        sys.exit(0 if result == 0 else 1)
        
    except Exception as e:
        logging.critical(f"ERREUR GLOBALE : {str(e)}", exc_info=True)
        sys.exit(2)
        
    finally:  # Correctement aligné avec le try
        pythoncom.CoUninitialize()