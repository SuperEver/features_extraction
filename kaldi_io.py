"""numpy-kaldi i/o interface
"""

def ark2dict(arkfile):  # bufferized version
    """Kaldi archive (ark) to dictionnary of numpy arrays (~npz)

    ..note: Only standard features files supported, and float (no doubles)
    """
    res = {}
    with open(arkfile) as fin:
        while True:
            #TODO: break if empty buffer here
            fname = ''
            c = fin.read(1)
            if c == '':  # EOF (EOFError not raised by read(empty))
                break
            while c != ' ':
                fname += c
                c = fin.read(1)
            logging.debug(fname)
            # end of fname
            fin.read(1)
            # data type
            assert fin.read(4) == 'BFM ', 'type not supported'
            # nrows type
            assert struct.unpack('b', fin.read(1))[0] == 4,  'type not supported'
            nrows = struct.unpack('i', fin.read(4))[0]
            # ncols type:
            assert struct.unpack('b', fin.read(1))[0] == 4,  'type not supported'
            ncols = struct.unpack('i', fin.read(4))[0]
            # data
            size = nrows * ncols * 4
            data = np.fromstring(fin.read(size), dtype=np.float32).reshape((nrows, ncols))
            res[fname] = data
    return res


def dict2ark(dictionnary, handler):
    """Write a dictionnary of numpy arrays to a kaldi ark file

    Parameters:
    -----------
    dictionnary: dict
    handler: fileObject, (opened file, sys.stdout, ...)
    """
    for fname, data in dictionnary.iteritems():
        if data.dtype == np.float32:
            handler.write(fname + ' BFM ')
        elif data.dtype == np.float64:
            handler.write(fname + ' BDM ')
        else:
            logging.warning('Invalid data type for {}: {}'
                            .format(fname, data.dtype))
            logging.warning('converting data type to C float')
            data = data.astype(np.float32)
            handler.write(fname + ' BFM ')
        nrows, ncols = data.shape
        handler.write(struct.pack('bibi', 4, nrows, 4, ncols))
        handler.write(data.tobytes())

        
def kalditext2python(textfile):
    logging.debug('kaldi text file to numpy array: {}'.format(textfile))
    res = {}
    tmparr = []
    arrname = ''
    with open(textfile) as fin:
        for line in fin:
            splitted = line.strip().split()
            if splitted[-1] == '[':
                if arrname:
                    res[arrname] = np.array(tmparr)
                arrname = splitted[0]
            else:
                if splitted[-1] == ']':
                    splitted = splitted[:-1]
                tmparr.append(map(float, splitted))
        res[arrname] = np.array(tmparr)
    return res
