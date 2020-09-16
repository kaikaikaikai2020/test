def add_lot_size(df, lot_size_col):
	if lot_size_col in df:
		df[lot_size_col].fillna(1.0, inplace= True)
	else:
		df[lot_size_col] = 1.0

	return df

def add_contract_size(df, contract_size_col):
	if contract_size_col in df:
		df[contract_size_col].fillna(1.0, inplace= True)
	else:
		df[contract_size_col] =1.0

	return df
	